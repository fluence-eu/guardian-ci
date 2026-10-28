# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'rails/generators'
require 'generators/guardian_ci/install_generator'

RSpec.describe GuardianCi::InstallGenerator do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.remove_entry(tmpdir) }

  def run_generator(args = [])
    # Capture stdout to keep RSpec output clean — Thor's `say` writes
    # progress lines that are noise during test runs.
    original = $stdout
    $stdout = StringIO.new
    described_class.start(args, destination_root: tmpdir)
  ensure
    $stdout = original
  end

  describe '#install' do
    it 'copies bin/guardian-ci into the host app' do
      run_generator
      target = File.join(tmpdir, 'bin/guardian-ci')
      expect(File.exist?(target)).to be true
    end

    it 'marks bin/guardian-ci as executable' do
      run_generator
      target = File.join(tmpdir, 'bin/guardian-ci')
      expect(File.executable?(target)).to be true
    end

    it 'ships a script that delegates to Guardian::Ci::CLI' do
      run_generator
      target = File.join(tmpdir, 'bin/guardian-ci')
      content = File.read(target)
      expect(content).to include('#!/usr/bin/env ruby')
      expect(content).to include("require 'guardian/ci/cli'")
      expect(content).to include('Guardian::Ci::CLI.start(argv)')
      expect(content).to include('ARGV.empty? ? %w[all] : ARGV')
    end

    it 'does not touch config/ci.rb' do
      FileUtils.mkdir_p(File.join(tmpdir, 'config'))
      original = "CI.run do\n  step 'X', 'cmd'\nend\n"
      File.write(File.join(tmpdir, 'config/ci.rb'), original)
      run_generator
      expect(File.read(File.join(tmpdir, 'config/ci.rb'))).to eq(original)
    end
  end
end
