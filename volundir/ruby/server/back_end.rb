# frozen_string_literal: true

module Volundir
  module Server
    class BackEnd < Volundir::IngotBase
      def self.start_server(args)
        port = args.first || '3000'
        puts "Starting Volundir server on port #{port}..."
      end
    end
  end
end
