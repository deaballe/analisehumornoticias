relative_root = Rails.application.config.relative_url_root.to_s.chomp("/")

if relative_root.present?
  module RelativeUrlRootMiddleware
    class FixScriptName
      def initialize(app, prefix)
        @app = app
        @prefix = prefix
      end

      def call(env)
        env = env.dup
        script_name = env["SCRIPT_NAME"].to_s
        env["SCRIPT_NAME"] = script_name.start_with?(@prefix) ? script_name : "#{@prefix}#{script_name}"
        @app.call(env)
      end
    end
  end

  Rails.application.config.middleware.insert_before 0, RelativeUrlRootMiddleware::FixScriptName, relative_root
end
