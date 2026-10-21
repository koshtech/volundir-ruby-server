# frozen_string_literal: true

module Volundir
  module Server
    module BackEnd
      module Controllers
        class Home
          def self.index(env)
            [200, { 'Content-Type' => 'application/json' }, ['{"message": "Welcome to Volundir BackEnd"}']]
          end
        end
      end
    end
  end
end
