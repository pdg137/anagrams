require 'rails_helper'

describe ChatChannel, type: :channel, connection: ApplicationCable::Connection do
  self._connection_class = ApplicationCable::Connection

  let(:websocket) { instance_double(ActionCable::Connection::WebSocket, transmit: nil) }
  let(:game) { Game.create!(log: 'ABCD') }
  let(:default_status) { "Visible letters: (none)\nNo words have been played yet." }

  before do
    connect
    connection.instance_variable_set(:@server, ActionCable.server)
    connection.instance_variable_set(:@coder, ActiveSupport::JSON)
    connection.instance_variable_set(:@websocket, websocket)
  end

  let(:room) { "game-#{game.id}" }

  it 'streams from the room and broadcasts a connect message' do
    expect {
      subscribe room: room
    }.to have_broadcasted_to(room).with(chat: 'Someone connected', status: default_status)
    expect(subscription).to have_stream_from(room)
  end

  it 'broadcasts a disconnect message when unsubscribed' do
    subscribe room: room
    expect {
      unsubscribe
    }.to have_broadcasted_to(room).with(chat: 'Someone disconnected', status: default_status)
  end

  it 'broadcasts messages with the default nickname' do
    subscribe room: room
    expect {
      perform :say, message: 'Hello everyone'
    }.to have_broadcasted_to(room).with(chat: 'Someone said: Hello everyone', status: default_status)
  end

  it 'changes nickname with /nick and uses it for subsequent messages' do
    subscribe room: room
    expect {
      perform :say, message: '/nick Alice'
    }.to have_broadcasted_to(room).with(chat: 'Someone set nickname to Alice', status: default_status)
    expect {
      perform :say, message: 'Hi there'
    }.to have_broadcasted_to(room).with(chat: 'Alice said: Hi there', status: default_status)
  end

  it 'shows the current board state for /look' do
    allow(game).to receive(:visible_letters).and_return(%w[H I J])
    allow(game).to receive(:words).and_return({ 'Alice' => ['HOUSE', 'RIVER'], 'Bob' => ['CLOUD'], 'Charlie' => [] })
    allow(Game).to receive(:find_by).and_call_original
    allow(Game).to receive(:find_by).with(id: game.id).and_return(game)

    subscribe room: room
    allow(subscription.connection).to receive(:transmit)

    perform :say, message: '/look'

    expect(subscription.connection).to have_received(:transmit).with(
      identifier: subscription.instance_variable_get(:@identifier),
      message: {
        status: <<~END.chomp
          Visible letters: H I J
          Alice: HOUSE RIVER
          Bob: CLOUD
        END
      }
    )
  end

  it 'allows nicknames with digits' do
    subscribe room: room
    expect {
      perform :say, message: '/nick Alice123'
    }.to have_broadcasted_to(room).with(chat: 'Someone set nickname to Alice123', status: default_status)
    expect {
      perform :say, message: 'Howdy'
    }.to have_broadcasted_to(room).with(chat: 'Alice123 said: Howdy', status: default_status)
  end

  it 'rejects nicknames containing underscores' do
    subscribe room: room
    allow(subscription.connection).to receive(:transmit)

    expect {
      perform :say, message: '/nick Alice_123'
    }.not_to have_broadcasted_to(room)

    expect(subscription.connection).to have_received(:transmit).with(
      identifier: subscription.instance_variable_get(:@identifier),
      message: { chat: 'Invalid nickname: Alice_123' }
    )
  end

  it 'rejects nicknames containing spaces' do
    subscribe room: room
    allow(subscription.connection).to receive(:transmit)

    expect {
      perform :say, message: '/nick New Name'
    }.not_to have_broadcasted_to(room)

    expect(subscription.connection).to have_received(:transmit).with(
      identifier: subscription.instance_variable_get(:@identifier),
      message: { chat: 'Invalid nickname: New Name' }
    )

    expect {
      perform :say, message: 'Hello again'
    }.to have_broadcasted_to(room).with(chat: 'Someone said: Hello again', status: default_status)
  end

  it 'gives an error for unknown commands' do
    subscribe room: room
    allow(subscription.connection).to receive(:transmit)

    expect {
      perform :say, message: '/dance party'
    }.not_to have_broadcasted_to(room)

    expect(subscription.connection).to have_received(:transmit).with(
      identifier: subscription.instance_variable_get(:@identifier),
      message: { chat: 'Unknown command: /dance party' }
    )
  end

  it 'flips a letter with /flip' do
    allow(game).to receive(:flip).with('Someone').and_return('Z')
    allow(game).to receive(:visible_letters).and_return(%w[Z])
    allow(game).to receive(:words).and_return({})
    allow(Game).to receive(:find_by).and_call_original
    allow(Game).to receive(:find_by).with(id: game.id).and_return(game)

    subscribe room: room
    allow(subscription.connection).to receive(:transmit)

    expect {
      perform :say, message: '/flip'
    }.to have_broadcasted_to(room).with(
      chat: 'Someone flipped Z',
      status: "Visible letters: Z\nNo words have been played yet."
    )
  end
end
