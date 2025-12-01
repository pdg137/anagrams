require 'rails_helper'

describe ChatChannel, type: :channel, connection: ApplicationCable::Connection do
  self._connection_class = ApplicationCable::Connection

  let(:websocket) { instance_double(ActionCable::Connection::WebSocket, transmit: nil) }
  let(:game) { Game.create!(log: 'ABCD') }

  before do
    connect
    connection.instance_variable_set(:@server, ActionCable.server)
    connection.instance_variable_set(:@coder, ActiveSupport::JSON)
    connection.instance_variable_set(:@websocket, websocket)
  end

  let(:room) { "game-#{game.id}" }

  it 'streams from the room, broadcasts a connect message, and sends the motd with status' do
    allow(connection).to receive(:transmit)

    expect {
      subscribe room: room
    }.to have_broadcasted_to(room).with(chat: 'Someone connected.')

    expect(subscription).to have_stream_from(room)

    expect(connection).to have_received(:transmit).with(
      identifier: subscription.instance_variable_get(:@identifier),
      message: {
        chat: ChatChannel::MOTD,
        status: "Visible letters: (none)\nNo words have been played yet."
      }
    )
  end

  it 'broadcasts a disconnect message when unsubscribed' do
    subscribe room: room
    expect {
      unsubscribe
    }.to have_broadcasted_to(room).with(chat: 'Someone disconnected.')
  end

  it 'broadcasts messages' do
    subscribe room: room
    allow(subscription.connection).to receive(:nickname) { 'Angela' }

    expect {
      perform :say, message: 'Hello everyone'
    }.to have_broadcasted_to(room).with(chat: 'Angela said: Hello everyone')
  end

  it 'changes nickname with /nick and uses it for subsequent messages' do
    subscribe room: room
    expect {
      perform :say, message: '/nick Alice'
    }.to have_broadcasted_to(room).with(chat: 'Someone set nickname to Alice.')
    expect {
      perform :say, message: 'Hi there'
    }.to have_broadcasted_to(room).with(chat: 'Alice said: Hi there')
  end

  it 'shows help text for /help' do
    subscribe room: room
    allow(subscription.connection).to receive(:transmit)

    perform :say, message: '/help'

    expect(subscription.connection).to have_received(:transmit).with(
      identifier: subscription.instance_variable_get(:@identifier),
      message: { chat: ChatChannel::HELP_TEXT }
    )
  end

  it 'allows nicknames with digits' do
    subscribe room: room
    allow(subscription.connection).to receive(:transmit)

    perform :say, message: 'Howdy'
    expect(subscription.connection).to have_received(:transmit).with(
      identifier: subscription.instance_variable_get(:@identifier),
      message: { chat: 'First please set a nickname with /nick.' }
    )

    expect {
      perform :say, message: '/nick Alice123'
    }.to have_broadcasted_to(room).with(chat: 'Someone set nickname to Alice123.')

    expect {
      perform :say, message: 'Howdy'
    }.to have_broadcasted_to(room).with(chat: 'Alice123 said: Howdy')
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

    perform :say, message: 'Hello again'

    expect(subscription.connection).to have_received(:transmit).with(
      identifier: subscription.instance_variable_get(:@identifier),
      message: { chat: 'First please set a nickname with /nick.' }
    )
  end

  it 'gives an error for unknown commands' do
    subscribe room: room
    allow(subscription.connection).to receive(:transmit)

    expect {
      perform :say, message: '/dance party'
    }.not_to have_broadcasted_to(room)

    expect(subscription.connection).to have_received(:transmit).with(
      identifier: subscription.instance_variable_get(:@identifier),
      message: { chat: 'Unknown command: /dance' }
    )
  end

  it 'flips a letter with /flip' do
    allow(game).to receive(:flip).with('Angela').and_return('Z')
    allow(game).to receive(:visible_letters).and_return(%w[Z])
    allow(game).to receive(:words).and_return({})
    allow(Game).to receive(:find_by).with(id: game.id).and_return(game)

    subscribe room: room
    allow(subscription.connection).to receive(:nickname) { 'Angela' }
    allow(subscription.connection).to receive(:transmit)

    expect {
      perform :say, message: '/flip'
    }.to have_broadcasted_to(room).with(
      chat: 'Angela flipped Z.',
      status: "Visible letters: Z\nNo words have been played yet."
    )
  end

  it 'includes a status update when a player forms a word' do
    allow(Game).to receive(:find_by).with(id: game.id).and_return(game)
    allow(game).to receive(:try_steal).with('CAT').and_return(true)
    allow(game).to receive(:play_word).with('Angela', 'CAT').and_return(true)
    allow(game).to receive(:visible_letters).and_return(%w[R])
    allow(game).to receive(:words).and_return({ 'Angela' => ['CAT'] })

    subscribe room: room
    allow(subscription.connection).to receive(:nickname) { 'Angela' }

    expect {
      perform :say, message: 'cat'
    }.to have_broadcasted_to(room).with(
      chat: 'Angela made CAT.',
      status: "Visible letters: R\nAngela: CAT"
    )
  end
end
