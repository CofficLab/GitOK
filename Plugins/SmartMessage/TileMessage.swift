import SwiftUI
import OSLog

struct TileMessage: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MessageProvider
    
    @State var hovered = false
    @State var isPresented = false
    @State var live = false
    
    var message: SmartMessage? { m.messages.first }

    var body: some View {
        HStack {
                if let m = message, live {
                    Text(m.description).onAppear {
                        main.asyncAfter(deadline: .now() + 3, execute: {
                            self.live = false
                        })
                    }
                } else {
                    Image(systemName: "message")
                }
            }
            .onChange(of: message, {
                if message != nil {
                    self.live = true
                }
            })
            .onHover(perform: { hovering in
                hovered = hovering
            })
            .onTapGesture {
                self.isPresented.toggle()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 0))
            .popover(isPresented: $isPresented, content: {
                tableView
                .frame(height: 300)
                .frame(width: 600)
            })
    }

    var tableView: some View {
        GroupBox {
            Table(m.messages, columns: {
                TableColumn("消息") { message in
                    Text(message.description)
                }
                TableColumn("时间") { message in
                    Text(message.createdAt.string)
                }
            })
        }
        .padding(10)
        .background(BackgroundView.type1.opacity(0.1))
    }
    
    private func makeTitle(_ title: String) -> some View {
        HStack {
            Image(systemName: "display")
                .resizable()
                .frame(width: 20, height: 20)
                .padding(.horizontal, 5)
            Text(title).font(.title2)
        }.padding(.vertical, 10)
    }

    private func makeKeyValueItem(key: String, value: String) -> some View {
        HStack(alignment: .center, spacing: 5) {
            Text(key)
            Spacer()
            Text(value)
                .font(.footnote)
                .opacity(0.8)
        }.padding(5)
    }
}
