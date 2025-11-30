require 'rails_helper'

RSpec.describe Game, type: :model do
  subject { Game.new(log: log) }
  let(:log) { '' }

  describe '#is_within?' do
    specify do
      expect(subject.is_within?("abcd", "abcde")).to eq(true)
      expect(subject.is_within?("abcde", "abcd")).to eq(false)
      expect(subject.is_within?("boba", "bobba")).to eq(true)
      expect(subject.is_within?("boba", "boat")).to eq(false)
    end
  end

  describe '#subtract' do
    specify do
      expect(subject.subtract("abcd", "abcde")).to eq({'e' => 1})
      expect(subject.subtract("boba", "bobba")).to eq({'b' => 1})
    end
  end

  context 'empty log' do
    it 'shows all no letters' do
      expect(subject.hidden_letters).to eq []
      expect(subject.visible_letters).to eq []
    end
  end

  context 'no flips' do
    let(:log) { 'ABCD' }

    it 'shows all letters' do
      expect(subject.hidden_letters).to eq %w(A B C D)
      expect(subject.visible_letters).to eq []
    end
  end

  context 'flipped "A" and "C"' do
    let(:log) { <<END }
ABCD
Alice+A
Alice+C
END

    it 'shows the remaining letters' do
      expect(subject.hidden_letters).to eq %w(B D)
      expect(subject.visible_letters).to eq %w(A C)
    end
  end

  context 'flipped non-existent letter' do
    let(:log) { <<END }
ABCD
Alice+Z
END

    specify do
      expect { subject.hidden_letters }.to raise_error(LogError, /line 2/)
    end
  end

  context 'make CAB' do
    let(:log) { <<END }
ABCD
Alice+A
Bob+B
Carol+C
Alice:CAB
END

    specify do
      expect(subject.words['Alice']).to eq %w(CAB)
      expect(subject.visible_letters).to eq []
    end
  end

  context 'make CABA' do
    let(:log) { <<END }
ABCD
Alice+A
Bob+B
Carol+C
Alice:CABA
END

    specify do
      expect { subject.visible_letters }.to raise_error(LogError, /line 5/)
    end
  end

  context 'make CAB then ABCD' do
    let(:log) { <<END }
ABCD
Alice+A
Bob+B
Carol+C
Alice:CAB
Alice+D
Bob:ABCD
END

    specify do
      expect(subject.words['Alice']).to eq %w()
      expect(subject.words['Bob']).to eq %w(ABCD)
      expect(subject.visible_letters).to eq []
    end
  end

  context 'longer game' do
    let(:log) { <<END }
ABCDEFG
Alice+A
Bob+B
Carol+C
Alice:CAB
Alice+D
Bob+E
Carol+G
Bob:ABCD
Carol:DEABC
END

    specify do
      expect(subject.words['Alice']).to eq %w()
      expect(subject.words['Bob']).to eq %w()
      expect(subject.words['Carol']).to eq %w(DEABC)
      expect(subject.visible_letters).to eq ['G']
    end
  end

  context 'steal without rearranging' do
    let(:log) { <<END }
ABCDEFG
Alice+A
Bob+B
Carol+C
Alice:CAB
Alice+D
Bob:CABD
END

    specify do
      expect { subject.visible_letters }.to raise_error(/line 7/)
    end
  end

end
