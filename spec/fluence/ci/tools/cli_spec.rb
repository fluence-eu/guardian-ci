# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'stringio'
require 'fluence/ci/tools/cli'

RSpec.describe Fluence::Ci::Tools::CLI do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.remove_entry(tmpdir) }

  around do |example|
    Dir.chdir(tmpdir) { example.run }
  end

  describe 'install' do
    it 'generates lib/tasks/fluence_ci.rake in a fresh directory' do
      expect { described_class.start(['install']) }.to output(%r{Generated lib/tasks/fluence_ci\.rake}).to_stdout
      expect(File.exist?('lib/tasks/fluence_ci.rake')).to be true
      expect(File.read('lib/tasks/fluence_ci.rake')).to include('namespace :fluence_ci')
    end

    it 'refuses to overwrite without --force' do
      FileUtils.mkdir_p('lib/tasks')
      File.write('lib/tasks/fluence_ci.rake', 'existing content')
      expect { described_class.start(['install']) }.to raise_error(SystemExit)
      expect(File.read('lib/tasks/fluence_ci.rake')).to eq('existing content')
    end

    it 'overwrites with --force' do
      FileUtils.mkdir_p('lib/tasks')
      File.write('lib/tasks/fluence_ci.rake', 'existing content')
      described_class.start(['install', '--force'])
      expect(File.read('lib/tasks/fluence_ci.rake')).to include('namespace :fluence_ci')
    end
  end

  describe 'version' do
    it 'prints the gem version' do
      expect { described_class.start(['version']) }
        .to output("fluence-ci-tools #{Fluence::Ci::Tools::VERSION}\n").to_stdout
    end
  end

  describe 'check' do
    it 'raises Thor::Error on unknown group' do
      expect { described_class.start(%w[check bogus]) }.to raise_error(SystemExit)
    end
  end
end
