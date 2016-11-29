require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "pry"
require "redcarpet"


#configures Sinatra to use sessions
configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

def data_path
  if ENV["RACK_ENV"] == "test"
    # "./test/data"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
    # "./data"
  end
end

def render_markdown(md_file)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(File.read(md_file))
end

def readfile(path)
  file_ext = File.extname(path)
  case file_ext
  when ".txt"
    headers["Content-Type"] = "text/plain"
    File.read(path)
  when ".md"
    render_markdown(path)
  end
end

get "/" do

  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map { |file| File.basename(file) }

  erb :index
end

get "/:file" do

  filename = params[:file]
  file_path = File.join(data_path, params[:file])

  if File.exists?(file_path) #("data/#{filename}")
    readfile(file_path)
  else
    session[:error] = "#{filename} doesn't exist" unless filename == "favicon.ico"
    redirect "/"
  end
end

get "/edit/:file" do
  # filename = params[:file]
  # @file = File.read("data/#{filename}")
  file_path = File.join(data_path, params[:file])

  @content = File.read(file_path)

  erb :edit_file
end

post "/update/:file" do
  filename = params[:file]
  file_path = File.join(data_path, filename)

  file = File.read(file_path)

  if params[:updated_text] != file
    File.open(file_path, "w+") { |f| f.write(params[:updated_text])}
    session[:update_msg] = "#{filename} has been updated."
  else
    session[:update_msg] = "No changes made to #{filename}"
  end
    redirect "/"

end


