require 'sinatra'
require 'pg'
require 'json'
require 'base64'


set :bind, '0.0.0.0'

before do
   @db = PG.connect(host: 'localhost', dbname: 'chatitude_dev')
end

get '/' do
  send_file 'public/index.html'
end

post '/signup' do
  #params = JSON.parse request.body.read
  if (params['username'] && params['password'])
    exists = @db.exec("SELECT * FROM users WHERE username = $1",[params['username']]).first

    if (exists == nil)
      #create token
      apiToken = Base64::encode64(params['username'] + params['password'])
      @db.exec("INSERT INTO users (username, password, apitoken) VALUES ($1, $2, $3)",[params['username'],params['password'],apiToken]).first
      return status 200
    end
  end
  return status 400
end

post '/signin' do

  headers['Content-Type'] = 'application/json'

    username = params['username']
    password = params['password']

    puts "#{username} signed in!"
    puts "Username : [#{params['username']}], Password : [#{params['password']}]"

    # TODO: Grab user by username from database and check password
    owner = @db.exec("SELECT * FROM users WHERE username = $1",[params['username']]).first
    # Validate credentials Valid
    if !owner.nil? && password == owner['password']
      headers['Content-Type'] = 'application/json'

      # TODO: Return all pets adopted by this user
      return {"apiToken" => owner['apitoken']}.to_json

    end
    return status 401
end

get '/chats' do
  headers['Content-Type'] = 'application/json'
  if (params['since'])
    return params['since']#where time > since
  else
    chats = @db.exec("SELECT id,message,name AS user,time FROM chats ORDER BY time DESC LIMIT 10").to_a
    chats.each do |v|
      v['id'] =  v['id'].to_i
    end
    chats = chats.reverse()
    return chats.to_json
  end
end

post '/chats' do
  if (params['apiToken'] && params['message'] != "")
    user = @db.exec("SELECT username, apitoken FROM users WHERE apitoken = $1;", [params['apiToken']]).first
    @db.exec("INSERT INTO chats (name, message) VALUES ($1, $2);",[user['username'], params['message']]).first
    return status 200
  else
    return status 401
  end
end
