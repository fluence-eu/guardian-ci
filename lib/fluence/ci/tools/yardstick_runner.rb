# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require 'yardstick'

module Fluence
  module Ci
    module Tools
      # In-process yardstick measure + threshold check. Reads
      # `.yardstick.yml` for config (threshold, rules, paths), writes
      # the textual report to `doc/yardstick_report.txt`, and exits 1
      # when coverage is below the configured threshold — same contract
      # as `Yardstick::Rake::Verify` but without requiring the consumer
      # to register that rake task in its Rakefile.
      module YardstickRunner
        REPORT_PATH = 'doc/yardstick_report.txt'

        # Measure yardstick coverage, write the textual report to
        # {REPORT_PATH}, and exit 1 if coverage is below the threshold
        # configured in `.yardstick.yml`.
        # @return [void]
        # @raise [SystemExit] when coverage is below the threshold
        # @api public
        def self.run!
          config = load_config
          measurements = ::Yardstick.measure(config)
          FileUtils.mkdir_p(File.dirname(REPORT_PATH))
          File.open(REPORT_PATH, 'w') { |io| measurements.puts(io) }
          coverage = ::Yardstick.round_percentage(measurements.coverage * 100)
          puts "YARD-Coverage: #{coverage}% (threshold: #{config.threshold}%)"
          return if coverage >= config.threshold

          warn "YARD-Coverage must be at least #{config.threshold}% but was #{coverage}%"
          exit 1
        end

        # Load `.yardstick.yml` (or {} when missing) and coerce it into
        # a `Yardstick::Config` so threshold + rules + paths are honoured.
        # @return [Yardstick::Config]
        # @api private
        def self.load_config
          data = File.exist?('.yardstick.yml') ? (YAML.load_file('.yardstick.yml') || {}) : {}
          ::Yardstick::Config.coerce(data)
        end
      end
    end
  end
end
