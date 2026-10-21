# frozen_string_literal: true

module Volundir
  module Server
    module BackEnd
      module Controllers
        class Health
          def self.check(env)
            [200, { 'Content-Type' => 'application/json' }, ['{"status": "ok"}']]
          end
        end
      end
    end
  end
end
