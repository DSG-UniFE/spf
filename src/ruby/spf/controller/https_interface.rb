require 'warden'
require 'concurrent'
require 'sinatra/base'
require 'sinatra/flash'

require 'spf/common/logger'
require 'spf/common/exceptions'
require 'spf/common/extensions/fixnum'

# require_relative './sinatra_ssl'
require_relative './https_interface_model'

class HttpsInterface < Sinatra::Base

  include SPF::Logging

  CERTIFICATE_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'resources', 'certificates'))

  set :title, "SPF Demo"
  set :server, %w[webrick]
  # set :ssl_certificate, "#{CERTIFICATE_DIR}/cert.crt"
  # set :ssl_key, "#{CERTIFICATE_DIR}/pkey.pem"
  set :port, 8433
  set :bind, "0.0.0.0"

  enable :sessions
  register Sinatra::Flash

  # Timeout
  @@SEND_DATA_TIMEOUT = 5.seconds,

  @CONTROLLER_PORT = 52161

  use Warden::Manager do |config|
    # Tell Warden how to save our User info into a session.
    # Sessions can only take strings, not Ruby code, we'll store
    # the User's `id`
    config.serialize_into_session{|user| user.id }
    # Now tell Warden how to take what we've stored in the session
    # and get a User from that information.
    config.serialize_from_session{|id| User.get(id) }

    config.scope_defaults :default,
      # "strategies" is an array of named methods with which to
      # attempt authentication. We have to define this later.
      strategies: [:password, :signup],
      # The action is a route to send the user to when
      # warden.authenticate! returns a false answer. We'll show
      # this route below.
      action: 'unauthenticated'

    # When a user tries to log in and cannot, this specifies the
    # app to send the user to.
    config.failure_app = self
  end

  Warden::Manager.before_failure do |env,opts|
    # Because authentication failure can happen on any request but
    # we handle it only under "post '/unauthenticated'", we need
    # to change request to POST
    env['REQUEST_METHOD'] = 'POST'
    # And we need to do the following to work with  Rack::MethodOverride
    env.each do |key, value|
      env[key]['_method'] = 'post' if key == 'rack.request.form_hash'
    end
  end

  Warden::Strategies.add(:password) do
    def valid?
      params && params['username'] && params['password']
    end

    def authenticate!
      user = User.first(username: params['username'])

      if user.nil?
        throw(:warden, message: "The username you entered does not exist.")
      elsif user.authenticate(params['password'])
        success!(user)
      else
        throw(:warden, message: "The username and password combination ")
      end
    end
  end

  Warden::Strategies.add(:signup) do
    def valid?
      params && params['username'] && params['password']
    end

    def authenticate!
      username = params['username']
      password = params['password']
      if username.nil? || password.nil?
        throw(:warden, message: "The username or password must not be blank!")
      else
        user = User.new(username: username, password: password)
        if user.valid?
          user.save
          success!(user)
        else
          throw(:warden, message: "The username is already used!")
        end
      end
    end
  end

  get '/' do
    erb :index
  end

  post '/request', :provides => [ 'html', 'json' ] do
    puts "prima della env['warden'].authenticate! :password"
    puts "request.cookies: #{request.cookies}"
    puts "request.body.read: #{request.body.read}"

    env['warden'].authenticate! :password

    puts "prima della request.body.read"

    data = request.body.read

    puts "------------ #{data}"

    translate_request(data)
  end

  get '/signup' do
    erb :signup
  end

  post '/signup' do
    env['warden'].authenticate! :signup

    if session.nil? || [:return_to].nil?
      flash[:error] = env['warden.options'][:message]
      redirect '/signup'
    else
      flash[:success] = "Successfully logged in"
      redirect '/protected'
    end
  end

  get '/login' do
    erb :login
  end

  post '/login', :provides => [ 'html', 'json'] do
    puts "request.cookies: #{request.cookies}"
    puts "request.body.read: #{request.body.read}"

    env['warden'].authenticate! :password

    if session[:return_to].nil?
      # redirect '/protected'
      pass
    else
      flash[:success] = "Successfully logged in"
      # redirect session[:return_to]
    end
  end

  get '/logout' do
    env['warden'].raw_session.inspect
    env['warden'].logout(:default)
    flash[:success] = 'Successfully logged out'
    redirect '/login'
  end

  post '/unauthenticated' do
    if env['warden.options'][:attempted_path] == "/signin"
      flash[:error] = env['warden.options'][:message] || "The username is already used!"
      redirect '/login'
    else
      session[:return_to] = env['warden.options'][:attempted_path] if session[:return_to].nil?

      # Set the error and use a fallback if the message is not defined
      flash[:error] = env['warden.options'][:message] || "You must log in"
      redirect '/login'
    end
  end

  get '/protected' do
    puts "prima della env['warden'].authenticate! :password"
    puts "request.cookies: #{request.cookies}"
    puts "request.body.read: #{request.body.read}"

    env['warden'].authenticate! :password

    erb :protected
  end

  not_found do
    redirect '/login' # catch redirects to GET '/session'
  end

  # {
  # "Userid" : "Recon1",
  #   "RequestType": "surveillance/basic",
  #   "Service": "count object",
  #   "CameraGPSLatitude" : "44.12121",
  #   "CameraGPSLongitude" : "12.21212",
  #   "CameraUrl": "http://weathercam.digitraffic.fi/C0150200.jpg"
  # }

  # REQUEST participants/find_text
  # User 3;44.838124,11.619786;find "water"
  #
  # OR
  #
  # REQUEST surveillance/basic
  # User 3;44.838124,11.619786;face_recognition;https://example.info/camId.jpg
  def translate_request(data)
    if data.nil?
      return
    end
    puts "Ciao"
    logger.info "*** Received request: #{data} ***"
    Thread.new do
      begin
        status = Timeout::timeout(@@SEND_DATA_TIMEOUT) do
          s = TCPSocket.open("localhost", @CONTROLLER_PORT)

          socket.puts("REQUEST #{data['RequestType']} ")
          socket.puts("User #{data['Userid']};#{data['CameraGPSLatitude']};#{data['CameraGPSLongitude']};#{data['Service']};#{data['CameraUrl']}")
          socket.flush
          logger.info "*** #{self.class.name}: Send request to controller for user #{data['Userid']} ***"
        end
      rescue Timeout::Error => e
        logger.warn "*** #{self.class.name}: Failed send request to controller for user #{data['Userid']}, timeout error ***"
      rescue => e
        logger.warn "*** #{self.class.name}: Failed send request to controller for user #{data['Userid']}, controller is unreachable ***"
      ensure
        unless socket.nil?
          socket.close
        end
      end
    end

    logger.info "*** Finished translate_request for: #{data} ***"
  end

end
