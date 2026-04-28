# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'fluence/ci/tools/steps'

RSpec.describe Fluence::Ci::Tools::Steps do
  let(:host_class) do
    Class.new do
      include Fluence::Ci::Tools::Steps

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
  end

  describe '#docs' do
    it 'registers yard and yardstick' do
      host.docs
      expect(host.steps.map(&:first)).to eq(['Docs: yard', 'Docs: yardstick'])
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
      Fluence::Ci::Tools::Steps.module_eval do
        def accessibility
          step 'A11y: axe', 'bundle exec axe-rspec'
        end
      end
      host.all
      expect(host.steps.map(&:first)).to include('A11y: axe')
    ensure
      if Fluence::Ci::Tools::Steps.method_defined?(:accessibility)
        Fluence::Ci::Tools::Steps.send(:remove_method, :accessibility)
      end
    end
  end
end
