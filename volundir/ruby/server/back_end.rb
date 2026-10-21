# frozen_string_literal: true
require 'puma'
require 'json'

APP_ROOT          = "#{APPS_ROOT}/back_end"
APP_DOCUMENT_ROOT = "#{APP_ROOT}/public_html"
APP_CONFIG_PATH   = "#{APP_ROOT}/config"

module Volundir
  module Server
    module BackEnd
      class << self
        attr_accessor :routes, :public_root

        def initialize_router!
          @routes = {}
          @public_root = APP_DOCUMENT_ROOT || Dir.pwd
        end

        def register_route(path, handler)
          @routes[path] = handler
        end

        def load_static_routes(routes_file_path)
          if File.exist?(routes_file_path)
            ext = File.extname(routes_file_path)
            if ext == '.json'
              data = JSON.parse(File.read(routes_file_path))
              data.each { |path, handler| register_route(path, handler) }
            elsif ext == '.rb'
              require routes_file_path
            end
          end
        end

        def start_server(args)
          initialize_router!
          static_json = File.join(APP_CONFIG_PATH, '/routes/static.json')
          load_static_routes(static_json)

          if defined?(Volundir::Runtime::Registry) && Volundir::Runtime::Registry.respond_to?(:current)
            Volundir::Runtime::Registry.current.loaded_ingots.each do |name, data|
              Dir[File.join(data[:dir], 'config', 'routes', '*.{json,rb')].each do |r_file|
                load_static_routes(r_file)
              end
            end
          end

          port        = args.first          || ENV['PORT']      || '3000'
          environment = ENV['VOLUNDIR_ENV'] || ENV['INGOT_ENV'] || ENV['RACK_ENV'] || 'development'

          puts "Starting Volundir server on port #{port} [#{environment}]..."
          puts "Public root directory: #{@public_root}"

          app = Proc.new do |env|
            path_info   = env['PATH_INFO']
            handler_str = @routes[path_info]

            if handler_str
              if handler_str.is_a?(String) && handler_str.include?('.')
                klass_name, method_name = handler_str.split('.')
                klass = Object.const_get(klass_name)
                klass.send(method_name, env)
              elsif handler_str.respond_to?(:call)
                handler_str.call(env)
              else
                [500, { 'Content-Type' => 'text/plain' }, ['Internal Server Error: Invalid Route Handler']]
              end
            else
              [404, { 'Content-Type' => 'application/json' }, ['{"error": "Not Found"}']]
            end
          end

          puma_server = Puma::Server.new(app)
          puma_server.add_tcp_listener('0.0.0.0', port)
          puma_server.run

          Signal.trap('INT') { puma_server.stop; exit 0 }
          sleep
        end
      end
    end
  end
end
