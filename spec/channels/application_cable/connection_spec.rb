require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  it 'defaults to Someone when no nickname cookie is present' do
    connect "/cable"
    expect(connection.nickname).to eq('Someone')
  end

  it 'uses the nickname from the cookie when provided' do
    cookies[ApplicationCable::Connection::NICKNAME_COOKIE] = 'Alice123'
    connect "/cable"
    expect(connection.nickname).to eq('Alice123')
  end

  it 'ignores invalid cookie values' do
    cookies[ApplicationCable::Connection::NICKNAME_COOKIE] = 'Bad Name'
    connect "/cable"
    expect(connection.nickname).to eq('Someone')
  end
end
