require 'rubygems'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'bcrypt'

DB_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'resources'))

DataMapper.setup(:default, "sqlite://#{DB_DIR}/users_db.sqlite")

class User
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :username, String, :length => 3..50, :unique => true
  property :password, BCryptHash

  def authenticate(attempted_password)
      if self.password == attempted_password
        true
      else
        false
      end
    end

end

DataMapper.finalize
DataMapper.auto_upgrade!
