require 'rails_helper'
require 'dictionary'
require 'securerandom'
require 'fileutils'

RSpec.describe Dictionary do
  describe '.check' do
    it 'returns true for entries found in the dictionary irrespective of case' do
      expect(Dictionary.check('cat')).to be true
      expect(Dictionary.check('DOG')).to be true
    end

    it 'returns false when the word is missing' do
      expect(Dictionary.check('dogcat')).to be false
    end

    it 'ignores blank input' do
      expect(Dictionary.check('   ')).to be false
    end

    it 'only reads the dictionary file once' do
      Dictionary.reset!
      expect(File).to receive(:foreach).once.and_call_original
      2.times { Dictionary.check('cat') }
    end
  end
end
