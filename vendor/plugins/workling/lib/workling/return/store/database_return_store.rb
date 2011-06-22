require 'workling/return/store/base'

#
#  How to use:
#  1. Create a migration that has two fields: key (string) and value (text). The table is return_stores.
#  2. Create a model called ReturnStore. Add "serialize :value" to the model and validate the presence of key.
#  3. You're done.
#
#  This really should have been called ActiveRecordReturnStore though.
#
module Workling
  module Return
    module Store
      class DatabaseReturnStore < Base

        def initialize
          
        end

        def set(key, value)
          store = ReturnStore.find_by_key(key)
          store = ReturnStore.new({:key => key}) if store.nil?
          store.value = value
          store.save
        end

        def get(key)
          store = ReturnStore.find_by_key(key)
          return nil if store.nil?
          value = store.value
          return value
        end
      end
    end
  end
end