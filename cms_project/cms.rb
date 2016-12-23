require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "pry"
require "redcarpet"

USERNAME = "admin"
PASSWORD = "secret"


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

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)

  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    erb render_markdown(content)
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
    load_file_content(file_path)
  else
    session[:error] = "#{filename} doesn't exist"
    # Add the following code if you do not have the favicon.ico added to the publuc folder:
    #unless filename == "favicon.ico"
    redirect "/"
  end
end

get "/edit/:file" do

  if session[:signedin] != "true"
    session[:update_msg] = "You must be signed in to do that."
    redirect "/"
  else
    file_path = File.join(data_path, params[:file])

    @content = File.read(file_path)

    erb :edit_file
  end
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

get "/create/doc" do
  if session[:signedin] != "true"
    session[:update_msg] = "You must be signed in to do that."
    redirect "/"
  else
    erb :new_file
  end
end


post "/add/doc" do

  newfilename = params["docname"]

  if newfilename.size > 0

    file_path = File.join(data_path, newfilename)
    File.new(file_path, "w+")
    session[:update_msg] = "#{newfilename} has been created."
    redirect "/"
  else
    session[:update_msg] = "A name is required"
    status 422
    erb :new_file
  end
  # redirect "/"
end

post "/delete/:file" do
    if session[:signedin] != "true"
    session[:update_msg] = "You must be signed in to do that."
    redirect "/"
  else
    filename = params["file"]
    file_path = File.join(data_path, filename)
    File.delete(file_path)
    session[:update_msg] = "#{filename} was deleted."
    redirect "/"
  end
end

get "/users/signin/?:username?" do
  erb :signin
end

get "/users/signout" do
  session[:signedin] = "false"
  session[:update_msg] = "You have been signed out."
  redirect "/"
end

post "/users/validate" do
  @username = params["username"]

  if @username == USERNAME && params["password"] == PASSWORD
    session[:update_msg] = "Welcome!"
    session[:signedin] = "true"
    session[:username] = params["username"]
    redirect "/"
  else
    session[:update_msg] = "Invalid Credentials"
    redirect "/users/signin/#{@username}"
  end
end


