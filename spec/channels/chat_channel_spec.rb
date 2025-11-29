require 'rails_helper'

describe ChatChannel, type: :channel, connection: ApplicationCable::Connection do
  self._connection_class = ApplicationCable::Connection

  let(:websocket) { instance_double(ActionCable::Connection::WebSocket, transmit: nil) }

  before do
    connect
    connection.instance_variable_set(:@server, ActionCable.server)
    connection.instance_variable_set(:@coder, ActiveSupport::JSON)
    connection.instance_variable_set(:@websocket, websocket)
  end

  let(:room) { 'room1' }

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
end
