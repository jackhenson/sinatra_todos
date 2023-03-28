require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = session[:lists]

  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  erb :list, layout: :layout
end

# Edit an existing todo list
get '/lists/:id/edit' do
  @id = params[:id].to_i
  @list = session[:lists][@id]

  erb :edit_list, layout: :layout
end

# Returns an error message if name is invalid, or nil if valid
def error_for_list_name(name)
  if session[:lists].any? {|list| list[:name] == name}
    "List name must be unique."
  # Range#cover? faster than Range#include ?
  elsif !(1..100).cover? name.size
    "List name must be between 1 and 100 characters." 
  else
    nil
  end
end

def error_for_todo_name(todo_name)
  if !(1..100).cover? todo_name.size
    "Todo name must be between 1 and 100 characters." 
  else
    nil
  end
end

# Create a new list
post "/lists" do
  # String#strip prevents counting w/s characters
  list_name = params[:list_name].strip
  
  error = error_for_list_name(list_name)
  if error
    session[:error] = error_for_list_name(list_name)
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# Update an existing list
post "/lists/:id" do
  list_name = params[:list_name].strip
  @id = params[:id].to_i
  @list = session[:lists][@id]
  
  error = error_for_list_name(list_name)
  if error
    session[:error] = error_for_list_name(list_name)
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{@id}"
  end
end

# Create a new todo for a list
post "/lists/:list_id/todos" do
  todo_name = params[:todo].strip
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  error = error_for_todo_name(todo_name)
  if error
    session[:error] = error_for_todo_name(todo_name)
    erb :list, layout: :layout
  else
    @list[:todos] << {name: todo_name, completed: false}
    session[:success] = "The todo has been created."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo list
post "/lists/:id/destroy" do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "The list has been deleted"
  redirect "/lists"
end
