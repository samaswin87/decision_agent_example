class ApplicationController < ActionController::Base
  include PermissionCheckable
end
