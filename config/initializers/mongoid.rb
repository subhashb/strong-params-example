module Mongoid
  module Document
    include ActiveModel::ForbiddenAttributesProtection
  end
end
