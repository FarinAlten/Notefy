struct NoteEditor: View {
    @Binding var note: Note
    var onExport: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                TextField("Titel", text: $note.title)
                    .font(.title2.weight(.semibold))
                    .padding(.horizontal)
                    .padding(.top)

                Divider()

                RichTextView(text: $note.content)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .frame(maxHeight: .infinity)

                HStack {
                    Button("Exportieren", action: onExport)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.top)
        }
        .navigationTitle("Notiz bearbeiten")
    }
}