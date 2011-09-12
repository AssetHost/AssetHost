class ApiUser < ActiveRecord::Base
  devise :token_authenticatable
end
