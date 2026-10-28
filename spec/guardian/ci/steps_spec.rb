# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'guardian/ci/steps'

RSpec.describe Guardian::Ci::Steps do
  let(:host_class) do
    Class.new do
      include Guardian::Ci::Steps

      attr_reader :steps

      def initialize
        @steps = []
      end

      def step(label, command)
        @steps << [label, command]
      end
    end
  end
  let(:host) { host_class.new }

  describe '#lint' do
    it 'registers a single rubocop step' do
      host.lint
      expect(host.steps).to eq([['Style: rubocop', 'bundle exec rubocop']])
    end

    it 'writes JSON to tmp/fluence-report/rubocop.json in report mode' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) { host.lint(report: true) }
        expect(host.steps.last.last).to include('--format json --out tmp/fluence-report/rubocop.json')
      end
    end
  end

  describe '#security' do
    it 'registers brakeman, bundler-audit, ruby_audit' do
      host.security
      expect(host.steps.map(&:first)).to eq([
                                              'Security: brakeman',
                                              'Security: bundler-audit',
                                              'Security: ruby_audit'
                                            ])
    end

    it 'emits report-mode commands with output paths under tmp/fluence-report' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) { host.security(report: true) }
        commands = host.steps.map(&:last)
        expect(commands[0]).to include('--output tmp/fluence-report/brakeman.json')
        expect(commands[1]).to include('tee tmp/fluence-report/audit.txt')
        expect(commands[2]).to include('tee tmp/fluence-report/ruby_audit.txt')
      end
    end
  end

  describe '#codequality' do
    it 'defaults paths to lib' do
      host.codequality
      expect(host.steps.last.last).to include('lib')
    end

    it 'honours explicit paths' do
      host.codequality(paths: 'app lib')
      expect(host.steps.last.last).to include('app lib')
    end

    it 'emits machine-readable reports under tmp/fluence-report in report mode' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) { host.codequality(report: true) }
        commands = host.steps.map(&:last)
        expect(commands[0]).to include('--format json').and(include('> tmp/fluence-report/reek.json'))
        expect(commands[1]).to include('tee tmp/fluence-report/flog.txt')
        expect(commands[2]).to include('tee tmp/fluence-report/flay.txt')
      end
    end
  end

  describe '#docs' do
    it 'registers a parse-smoke yard step in default mode' do
      host.docs
      expect(host.steps).to eq([['Docs: yard', 'bundle exec yard doc --no-output --no-stats']])
    end

    it 'registers a HTML build step when build: true' do
      host.docs(build: true)
      expect(host.steps).to eq([['Docs: yard build', 'bundle exec yard doc']])
    end

    it 'invokes the in-process YardstickRunner in report mode' do
      host.docs(report: true)
      expect(host.steps.size).to eq(1)
      label, command = host.steps.first
      expect(label).to eq('Docs: yardstick')
      expect(command).to include('Guardian::Ci::YardstickRunner.run!')
    end

    it 'lets report: take precedence over build:' do
      host.docs(build: true, report: true)
      expect(host.steps.first.first).to eq('Docs: yardstick')
    end
  end

  describe '#tests' do
    context 'with explicit command' do
      it 'bypasses detection and registers a single Tests step' do
        host.tests(command: 'my-runner')
        expect(host.steps).to eq([%w[Tests my-runner]])
      end
    end

    context 'with auto-detection' do
      around do |example|
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) { example.run }
        end
      end

      it 'registers nothing when no helper file exists' do
        host.tests
        expect(host.steps).to be_empty
      end

      it 'registers an rspec step when spec/spec_helper.rb exists' do
        FileUtils.mkdir_p('spec')
        File.write('spec/spec_helper.rb', '')
        host.tests
        expect(host.steps).to eq([['Tests: rspec', 'bundle exec rspec']])
      end

      it 'registers a minitest step using bin/rails when present' do
        FileUtils.mkdir_p('test')
        FileUtils.mkdir_p('bin')
        File.write('test/test_helper.rb', '')
        File.write('bin/rails', '')
        host.tests
        expect(host.steps).to eq([['Tests: minitest', 'bin/rails test']])
      end

      it 'falls back to rake test for non-Rails minitest projects' do
        FileUtils.mkdir_p('test')
        File.write('test/test_helper.rb', '')
        host.tests
        expect(host.steps).to eq([['Tests: minitest', 'bundle exec rake test']])
      end

      it 'registers both runners when both helper files exist' do
        FileUtils.mkdir_p('spec')
        FileUtils.mkdir_p('test')
        File.write('spec/spec_helper.rb', '')
        File.write('test/test_helper.rb', '')
        host.tests
        expect(host.steps.map(&:first)).to eq(['Tests: rspec', 'Tests: minitest'])
      end
    end
  end

  describe '#all' do
    around do |example|
      Dir.mktmpdir { |dir| Dir.chdir(dir) { example.run } }
    end

    it 'runs every public method of the mixin' do
      host.all
      expected_groups = described_class.instance_methods(false).reject { |m| m == :all }.sort
      ran = host.steps.map(&:first).map { |label| label.split(':').first.downcase.to_sym }.uniq.sort
      expect(ran).to include(*expected_groups & %i[style security quality docs])
    end

    it 'forwards per-group overrides to the matching method' do
      host.all(codequality: { paths: 'app lib' })
      cq_steps = host.steps.select { |label, _| label.start_with?('Quality:') }
      expect(cq_steps.first.last).to include('app lib')
    end

    it 'picks up new step groups automatically (auto-pickup)' do
      Guardian::Ci::Steps.module_eval do
        def accessibility
          step 'A11y: axe', 'bundle exec axe-rspec'
        end
      end
      host.all
      expect(host.steps.map(&:first)).to include('A11y: axe')
    ensure
      Guardian::Ci::Steps.send(:remove_method, :accessibility) if Guardian::Ci::Steps.method_defined?(:accessibility)
    end

    it 'propagates report: true to every group method that accepts it' do
      host.all(report: true)
      commands = host.steps.map(&:last)
      expect(commands).to include(a_string_matching(%r{tmp/fluence-report/rubocop\.json}))
      expect(commands).to include(a_string_matching(%r{tmp/fluence-report/brakeman\.json}))
      expect(commands).to include(a_string_matching(%r{tmp/fluence-report/reek\.json}))
      expect(commands).to include(a_string_matching('Guardian::Ci::YardstickRunner.run!'))
    end

    it 'lets per-group overrides win over the global report flag' do
      host.all(report: true, codequality: { paths: 'lib' })
      cq_first = host.steps.find { |label, _| label.start_with?('Quality:') }
      expect(cq_first.last).not_to include('tmp/fluence-report')
    end
  end

  describe '.ensure_report_dir' do
    it 'creates tmp/fluence-report when missing' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          described_class.ensure_report_dir
          expect(Dir.exist?('tmp/fluence-report')).to be true
        end
      end
    end

    it 'is idempotent when the directory already exists' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('tmp/fluence-report')
          expect { described_class.ensure_report_dir }.not_to raise_error
        end
      end
    end
  end
end
