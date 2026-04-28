# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require 'yardstick'

module Fluence
  module Ci
    module Tools
      # In-process yardstick measure + verify, replicating the
      # `Yardstick::Rake::Measurement` + `Yardstick::Rake::Verify`
      # pair without requiring the consumer's Rakefile to define those
      # tasks. Reads `.yardstick.yml` (when present) for threshold and
      # rule config, writes the report to `doc/yardstick_report.txt`,
      # and exits 1 if coverage is below the configured threshold.
      #
      # Used by {Fluence::Ci::Tools::Steps#docs} in report mode so the
      # local pre-push (`bin/fluence-ci docs --report`) and the
      # centralized `ruby-gem-docs-measure` workflow share the same
      # measurement code path with zero Rakefile dependency.
      module YardstickRunner
        # Output path where yardstick's textual report is written.
        REPORT_PATH = 'doc/yardstick_report.txt'

        # Run measure + verify. Prints the coverage line to stdout and
        # writes the full report to {REPORT_PATH}. Raises `SystemExit`
        # with status 1 when coverage is below the configured threshold.
        # @return [void]
        # @raise [SystemExit] when coverage falls below the threshold
        # @api public
        def self.run!
          config = load_config
          measurements = ::Yardstick.measure(config)
          write_report(measurements)
          coverage = ::Yardstick.round_percentage(measurements.coverage * 100)
          threshold = config.threshold
          puts "YARD-Coverage: #{coverage}% (threshold: #{threshold}%)"
          return if coverage >= threshold

          warn "YARD-Coverage must be at least #{threshold}% but was #{coverage}%"
          exit 1
        end

        # Load .yardstick.yml (or {} when missing) and coerce to a
        # Yardstick::Config so threshold + rules + paths are honoured.
        # @return [Yardstick::Config]
        # @api private
        def self.load_config
          data = File.exist?('.yardstick.yml') ? (YAML.load_file('.yardstick.yml') || {}) : {}
          ::Yardstick::Config.coerce(data)
        end

        # Write the measurement set to {REPORT_PATH}, creating the
        # parent directory when missing.
        # @param measurements [Yardstick::MeasurementSet]
        # @return [void]
        # @api private
        def self.write_report(measurements)
          FileUtils.mkdir_p(File.dirname(REPORT_PATH))
          File.open(REPORT_PATH, 'w') { |io| measurements.puts(io) }
        end
      end
    end
  end
end
