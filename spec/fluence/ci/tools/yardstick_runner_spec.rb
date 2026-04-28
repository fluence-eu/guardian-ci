# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'yaml'
require 'fluence/ci/tools/yardstick_runner'

RSpec.describe Fluence::Ci::Tools::YardstickRunner do
  describe '.run!' do
    around do |example|
      Dir.mktmpdir { |dir| Dir.chdir(dir) { example.run } }
    end

    def write_yardstick_yml(threshold:)
      File.write('.yardstick.yml', YAML.dump('threshold' => threshold, 'path' => ['lib/**/*.rb']))
    end

    def write_lib(content)
      FileUtils.mkdir_p('lib')
      File.write('lib/foo.rb', content)
    end

    let(:documented_lib) do
      <<~RUBY
        # Foo module.
        module Foo
          # Returns the answer.
          # @return [Integer] the answer
          def self.bar
            42
          end
        end
      RUBY
    end

    let(:undocumented_lib) do
      <<~RUBY
        module Foo
          def self.bar
            42
          end
        end
      RUBY
    end

    it 'writes the report and returns when coverage meets the threshold' do
      write_yardstick_yml(threshold: 50)
      write_lib(documented_lib)
      expect { described_class.run! }
        .to output(/YARD-Coverage: \d+(\.\d+)?% \(threshold: 50%\)/).to_stdout
      expect(File.exist?('doc/yardstick_report.txt')).to be true
    end

    it 'aborts with a threshold message when coverage is below the threshold' do
      write_yardstick_yml(threshold: 100)
      write_lib(undocumented_lib)
      expect { described_class.run! }
        .to raise_error(SystemExit)
        .and output(/YARD-Coverage:/).to_stdout
        .and output(/must be at least 100%/).to_stderr
    end

    it 'falls back to default config when .yardstick.yml is absent' do
      write_lib(documented_lib)
      # Default Yardstick config sets threshold = 100 — a documented but
      # not @api-tagged module won't reach 100, so we expect an abort
      # against the default threshold rather than a nil-comparison crash.
      expect { described_class.run! }
        .to raise_error(SystemExit)
        .and output(/threshold: 100%/).to_stdout
    end
  end
end
