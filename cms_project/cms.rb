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

def render_mardown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def readfile(filename, file)
  file_type = File.extname(filename)
  case file_type
  when ".txt"
    headers["Content-Type"] = "text/plain"
    file
  when ".md"
    render_mardown(file)
  end
end

get "/" do
  # data_dir = Dir.new("data/")
  # @entries = data_dir.grep /.txt/

  @files = Dir["data/*.*"].map { |file| File.basename(file) }

  erb :index
end

get "/:file" do
  filename = params[:file]

  if File.exists?("data/#{filename}")
    file = File.read("data/#{filename}")
    readfile(filename, file)
  else
    session[:error] = "#{filename} doesn't exist" unless filename == "favicon.ico"
    redirect "/"
  end
end

get "/edit/:file" do
  # filename = params[:file]
  # @file = File.read("data/#{filename}")
  erb :edit_file
end

post "/update/:file" do
  filename = params[:file]
  file = File.read("data/#{filename}")

  if params[:updateText] != file
    File.open("data/#{filename}", "w+") { |f| f.write(params[:updateText])}
    session[:update_msg] = "#{filename} has been updated."
  else
    session[:update_msg] = "No changes made to #{filename}"
  end
    redirect "/"
end


