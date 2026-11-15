require 'rails_helper'

feature 'basic chat', type: :feature, js: true do
  def expect_chat_history_to_include(text)
    expect(page).to have_field('chat_output', with: /#{Regexp.escape(text)}/)
  end

  def expect_hidden_letters(text)
    expect(page).to have_field('hidden_letters_output', with: text)
  end

  it 'allows changing nickname and sending chat messages' do
    visit new_game_path
    click_button 'Create Game'

    expect(page).to have_css('#chat_input', wait: 5)
    expect(page).to have_css('#visible_letters', text: 'None')

    fill_in 'chat_input', with: '/nick Alice'
    click_button 'Say'
    expect_chat_history_to_include('Someone set nickname to Alice')

    fill_in 'chat_input', with: 'Hi there'
    click_button 'Say'
    expect_chat_history_to_include('Alice said: Hi there')
    expect(page).to have_css('#visible_letters', text: 'None')
  end

  it 'remembers nickname across disconnections' do
    visit new_game_path
    click_button 'Create Game'

    fill_in 'chat_input', with: '/nick Bob'
    click_button 'Say'
    expect_chat_history_to_include('Someone set nickname to Bob')

    # Simulate disconnect by refreshing the page (new websocket connection, same cookie)
    visit current_path

    fill_in 'chat_input', with: 'Hello again'
    click_button 'Say'
    expect_chat_history_to_include('Bob said: Hello again')
  end

  it 'displays visible letters as spans' do
    visit new_game_path
    click_button 'Create Game'
    expect(page).to have_css('#visible_letters', text: 'None', wait: 5)

    fill_in 'chat_input', with: '/nick Carol'
    click_button 'Say'

    click_button 'Flip'

    expect(page).to have_css('#visible_letters .letter', wait: 5)
  end

  it 'shows formed words for each player when they join or play' do
    game = Game.create!(log: <<~LOG)
      APPLECATSBANANA
      Alice+A
      Alice+P
      Alice+P
      Alice+L
      Alice+E
      Alice:APPLE
      Alice+C
      Alice+A
      Alice+T
      Alice+S
      Alice:CATS
      Bob+B
      Bob+A
      Bob+N
      Bob+A
      Bob+N
      Bob+A
    LOG
    visit game_path(game)

    within '.formed-words' do
      expect(page).to have_css('h3', text: 'Alice')
      expect(page).to have_css('.formed-word', text: 'APPLE')
      expect(page).to have_css('.formed-word', text: 'CATS')
      expect(page).to have_css('.formed-word .letter', count: 9)
    end

    fill_in 'chat_input', with: 'Bob'
    click_button 'Nick'
    fill_in 'chat_input', with: 'BANANA'
    click_button 'Say'

    within '.formed-words' do
      expect(page).to have_css('h3', text: 'Bob')
      expect(page).to have_css('.formed-word', text: 'BANANA')
      expect(page).to have_css('.formed-word .letter', count: 15)
    end
  end

  it 'shows only remaining hidden letters in the hidden letters panel' do
    game = Game.create!(log: 'A')
    visit game_path(game)
    click_button '▶'

    expect_hidden_letters('A')

    fill_in 'chat_input', with: 'Carol'
    click_button 'Nick'
    expect_chat_history_to_include('Someone set nickname to Carol.')
    click_button 'Flip'

    expect(page).to have_css('#visible_letters .letter', text: 'A')
    expect_hidden_letters('(none)')
  end

  it 'collapses and expands hidden letters while they keep updating' do
    game = Game.create!(log: 'A')
    visit game_path(game)

    expect(page).to have_css('#hidden_letters_output', visible: :hidden)
    expect(find('#hidden_letters_toggle').text).to eq('▶')

    click_button '▶'
    expect_hidden_letters('A')
    expect(find('#hidden_letters_toggle').text).to eq('▼')

    click_button '▼'
    expect(page).to have_css('#hidden_letters_output', visible: :hidden)
    expect(find('#hidden_letters_toggle').text).to eq('▶')

    fill_in 'chat_input', with: 'Carol'
    click_button 'Nick'
    expect_chat_history_to_include('Someone set nickname to Carol.')
    click_button 'Flip'

    click_button '▶'
    expect(page).to have_css('#visible_letters .letter', text: 'A')
    expect_hidden_letters('(none)')
    expect(find('#hidden_letters_toggle').text).to eq('▼')
  end

  it 'shows help without clearing a draft message' do
    visit new_game_path
    click_button 'Create Game'

    within '#chat' do
      expect(all('button').map(&:text)).to eq(%w[Say Dict Flip Nick Help])
    end

    fill_in 'chat_input', with: 'draft message'
    click_button 'Help'

    expect_chat_history_to_include('Available commands:')
    expect(page).to have_field('chat_input', with: 'draft message')
  end

  it 'uses the chat input for dictionary lookups and nicknames' do
    visit new_game_path
    click_button 'Create Game'

    fill_in 'chat_input', with: 'cat'
    click_button 'Dict'
    expect_chat_history_to_include('CAT is in the dictionary.')
    expect(page).to have_field('chat_input', with: '')

    fill_in 'chat_input', with: 'Alice'
    click_button 'Nick'
    expect_chat_history_to_include('Someone set nickname to Alice.')
    expect(page).to have_field('chat_input', with: '')
  end
end
