module AssetHostCore
  module Config
    class << self
      
      def current_user_method(&blk)
        @current_user = blk if blk
        @current_user
      end
      
      #----------
      
      def sign_out_path(&blk)
        @sign_out = blk if blk
        @sign_out
      end
      
      #----------
      
      def authentication_method(&blk)
        @authentication = blk if blk
        @authentication
      end
      
      #----------
      
      def api_authentication_method(&blk)
        @api_authentication = blk if blk
        @api_authentication
      end
    end
  end
end