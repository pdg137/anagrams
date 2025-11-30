require 'rails_helper'

feature 'basic chat', type: :feature, js: true do
  def expect_chat_history_to_include(text)
    expect(page).to have_field('chat_output', with: /#{Regexp.escape(text)}/, wait: 5)
  end

  def expect_status_to_include(text)
    expect(page).to have_field('status_output', with: /#{Regexp.escape(text)}/, wait: 5)
  end

  it 'allows changing nickname and sending chat messages' do
    visit new_game_path
    click_button 'Create Game'

    expect(page).to have_css('#chat_input', wait: 5)

    fill_in 'chat_input', with: '/look'
    click_button 'Say'
    expect_status_to_include('Visible letters: (none)')
    expect_status_to_include('No words have been played yet.')

    fill_in 'chat_input', with: '/nick Alice'
    click_button 'Say'
    expect_chat_history_to_include('Someone set nickname to Alice')
    expect_status_to_include('Visible letters: (none)')

    fill_in 'chat_input', with: 'Hi there'
    click_button 'Say'
    expect_chat_history_to_include('Alice said: Hi there')
    expect_status_to_include('Visible letters: (none)')
  end
end
