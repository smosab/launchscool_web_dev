require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require 'pry'

#configures Sinatra to use sessions
configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

helpers do
  def list_complete?(list)
    todos_count(list)> 0 && count_remaining_todos(list) == 0
  end

  def count_remaining_todos(list)
    list[:todos].count { |todo| todo[:completed] == false }
  end

  def todos_count(list)
    list[:todos].size
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

def sort_lists(lists, &block)

  complete_lists, incomplete_lists = lists.partition  { |list|
        list_complete?(list) }

  incomplete_lists.each  { |list| yield list, lists.index(list) }

  complete_lists.each  { |list| yield list, lists.index(list) }

end

def sort_todos(todos, &block)
  complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

  incomplete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

  incomplete_todos.each { |todo| yield todo, todos.index(todo) }
  complete_todos.each { |todo| yield todo, todos.index(todo) }
end
end

get "/" do
  redirect to("/lists")
end

# view lists of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

#render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

#Return an error message if the name is invalid. Return nil if valid.
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
   "The list name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name}
    "The list name must be unique"
  end
end

#Return an error message if the todo name is invalid. Return nil if valid.
def error_for_todo(name)
 "The todo must be between 1 and 100 characters." if !(1..100).cover?(name.size)
end

# create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created!"
    redirect "/lists"
  end
end

get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

#Edit an existing to do list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :edit_list, layout: :layout
end

#update an existing to do list
post  "/lists/:id" do
  # binding.pry

  list_name = params[:list_name].strip
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    # binding.pry
    @list[:name] = list_name
    session[:success] = "The list has been updated!"
    redirect "/lists/#{id}"
  end
end

#Delete an existing to do list
post "/lists/:id/delete" do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "The list has been deleted!"
  redirect "/lists"
end

#Delete an item from a todo list
post "/lists/:list_id/todos/:item_id/delete_item" do
  item_id = params[:item_id].to_i
  list_id = params[:list_id].to_i
  @list = session[:lists][list_id]
  # binding.pry
  @list[:todos].delete_at(item_id)
  session[:success] = "The item has been deleted!"
  redirect "/lists/#{list_id}"
end

#Complete/check-off an item from a todo list
post "/lists/:list_id/todos/:item_id" do
  @item_id = params[:item_id].to_i
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  is_completed = params[:completed] == "true"
  @list[:todos][@item_id][:completed] = is_completed

  session[:success] = "The todo has been updated!"
  redirect "/lists/#{@list_id}"
end

#Mark all todos as complete for a list
post "/lists/:list_id/complete_all" do

  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]


  @list[:todos].each {|todo| todo[:completed] = true }

  session[:success] = "All todos have been completed."
  redirect "/lists/#{@list_id}"
end

#Add Todo to a list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip

  error = error_for_todo(text)

  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << {name: text, completed: false }
    session[:success] = "The todo has been added!"
    redirect "/lists/#{@list_id}"
  end
end


