relative_root = Rails.application.config.relative_url_root

if relative_root.present?
  module RelativeUrlRootMiddleware
    class FixScriptName
      def initialize(app, prefix)
        @app = app
        @prefix = prefix.to_s.chomp("/")
      end

      def call(env)
        env = env.dup
        env["SCRIPT_NAME"] = "#{@prefix}#{env["SCRIPT_NAME"]}"
        @app.call(env)
      end
    end
  end

  Rails.application.config.middleware.insert_before 0, RelativeUrlRootMiddleware::FixScriptName, relative_root
end
