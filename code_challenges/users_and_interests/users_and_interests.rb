require 'sinatra'
require "sinatra/reloader"
require 'yaml'
require 'pry'

before do
  @list = Psych.load_file('data/users.yaml')
end


helpers do
  def count_interests
    @num_users = @list.keys.count
    # @num_interests = 0
    # @list.each_pair do |k, v|
    #   @num_interests += v[:interests].count
    # end
    @num_interests = @list.inject(0) { |sum, (user, details)| sum + details[:interests].count }
    "There are #{@num_users} users with a total of #{@num_interests} interests."
  end
end

get '/' do
  redirect to('/users_list')
end

get '/users_list' do
  erb :users_list
end

get '/user_profile/:user' do
  @user = params[:user]
  erb :user_profile
end


