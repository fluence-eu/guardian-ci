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

  describe 'group commands' do
    it 'exposes one top-level Thor command per Steps method' do
      Fluence::Ci::Tools::Steps.instance_methods(false).each do |group|
        expect(described_class.commands).to have_key(group.to_s)
      end
    end

    it 'each group command accepts a --report flag' do
      Fluence::Ci::Tools::Steps.instance_methods(false).each do |group|
        cmd = described_class.commands[group.to_s]
        expect(cmd.options).to have_key(:report)
      end
    end

    context 'dispatch to Runner' do
      # Use a real Runner so `runner.method(group).parameters` returns
      # the actual Steps signatures the CLI dispatch inspects. Stub
      # `step` and `report!` so the runner doesn't shell out, and assert
      # on the commands passed to `step` to prove the dispatch path.
      let(:runner) do
        Fluence::Ci::Tools::Runner.new(io: StringIO.new).tap do |r|
          allow(r).to receive(:step)
          allow(r).to receive(:report!)
        end
      end

      before { allow(Fluence::Ci::Tools::Runner).to receive(:new).and_return(runner) }

      it 'runs the default-mode command without --report' do
        described_class.start(['lint'])
        expect(runner).to have_received(:step).with('Style: rubocop', 'bundle exec rubocop')
      end

      it 'runs the report-mode command when --report is passed' do
        described_class.start(['lint', '--report'])
        expect(runner).to have_received(:step)
          .with('Style: rubocop', a_string_including('tmp/fluence-report/rubocop.json'))
      end

      it 'propagates --report to every group when calling all' do
        described_class.start(['all', '--report'])
        expect(runner).to have_received(:step)
          .with('Style: rubocop', a_string_including('tmp/fluence-report/rubocop.json'))
        expect(runner).to have_received(:step)
          .with('Quality: reek', a_string_including('tmp/fluence-report/reek.txt'))
      end
    end
  end
end
