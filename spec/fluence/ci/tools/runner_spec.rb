# frozen_string_literal: true

require 'stringio'
require 'fluence/ci/tools/runner'

RSpec.describe Fluence::Ci::Tools::Runner do
  let(:io) { StringIO.new }
  subject(:runner) { described_class.new(io: io) }

  describe '#step' do
    it 'is success? when the command exits 0' do
      runner.step('passing', 'true')
      expect(runner).to be_success
    end

    it 'is not success? when a command exits non-zero' do
      runner.step('failing', 'false')
      expect(runner).not_to be_success
    end

    it 'tracks every failed label' do
      runner.step('a', 'true')
      runner.step('b', 'false')
      runner.step('c', 'false')
      runner.step('d', 'true')
      expect(io.string).to include('a', 'b', 'c', 'd')
      expect(runner).not_to be_success
    end
  end

  describe '#report!' do
    it 'prints a success line and does not exit on success' do
      runner.step('ok', 'true')
      expect { runner.report! }.not_to raise_error
      expect(io.string).to include('All checks passed')
    end

    it 'exits 1 on failure' do
      runner.step('fail', 'false')
      expect { runner.report! }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      expect(io.string).to include('Failed: fail')
    end
  end
end
