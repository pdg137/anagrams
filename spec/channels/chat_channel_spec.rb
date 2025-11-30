require 'rails_helper'

describe ChatChannel, type: :channel, connection: ApplicationCable::Connection do
  self._connection_class = ApplicationCable::Connection

  let(:websocket) { instance_double(ActionCable::Connection::WebSocket, transmit: nil) }
  let(:game) { Game.create!(log: "") }

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
    }.to have_broadcasted_to(room).with('Someone connected')
    expect(subscription).to have_stream_from(room)
  end

  it 'broadcasts a disconnect message when unsubscribed' do
    subscribe room: room
    expect {
      unsubscribe
    }.to have_broadcasted_to(room).with('Someone disconnected')
  end

  it 'broadcasts messages with the default nickname' do
    subscribe room: room
    expect {
      perform :say, message: 'Hello everyone'
    }.to have_broadcasted_to(room).with('Someone said: Hello everyone')
  end

  it 'changes nickname with /nick and uses it for subsequent messages' do
    subscribe room: room
    expect {
      perform :say, message: '/nick Alice'
    }.to have_broadcasted_to(room).with('Someone set nickname to Alice')
    expect {
      perform :say, message: 'Hi there'
    }.to have_broadcasted_to(room).with('Alice said: Hi there')
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
      message: <<~END
        Visible letters: H I J
        Alice: HOUSE RIVER
        Bob: CLOUD
      END
    )
  end
end
