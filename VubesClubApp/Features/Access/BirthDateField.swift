import SwiftUI

/// Doğum tarihi için tarih ↔ "yyyy-MM-dd" dönüşümleri (cihazın takvimiyle, saat dilimi kayması olmadan).
enum BirthDate {
    static let earliest = Calendar.current.date(from: DateComponents(year: 1920, month: 1, day: 1)) ?? .distantPast

    /// Seçilebilecek en geç tarih: bugünden 18 yıl önce.
    static var latest: Date { Calendar.current.date(byAdding: .year, value: -18, to: .now) ?? .now }

    /// Çarkın başlangıç konumu (seçim yapılana kadar kaydedilmez).
    static var suggested: Date { Calendar.current.date(byAdding: .year, value: -25, to: .now) ?? .now }

    static func iso(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 1970, parts.month ?? 1, parts.day ?? 1)
    }

    static func date(fromISO value: String?) -> Date? {
        guard let value else { return nil }
        let pieces = value.split(separator: "-").compactMap { Int($0) }
        guard pieces.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: pieces[0], month: pieces[1], day: pieces[2]))
    }

    @MainActor
    static func display(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.shared.locale
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

/// Etiketli, dokununca tarih çarkı açan alan. Seçilene kadar boştur.
struct BirthDateField: View {
    let label: String
    @Binding var date: Date?
    var locked = false

    @State private var showsPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Overline(label)

            Button { showsPicker = true } label: {
                HStack {
                    Text(date.map(BirthDate.display) ?? L("Select your birth date"))
                        .font(Afterglow.body(15))
                        .foregroundStyle(date == nil ? Afterglow.muted.opacity(0.6) : Afterglow.text)

                    Spacer()

                    Image(systemName: locked ? "lock" : "calendar")
                        .font(.system(size: 14))
                        .foregroundStyle(Afterglow.muted)
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 49, alignment: .leading)
                .background(Afterglow.surface, in: .rect(cornerRadius: 8))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(locked)
            .accessibilityLabel(L(label))
            .accessibilityValue(date.map(BirthDate.display) ?? L("Not selected"))
        }
        .sheet(isPresented: $showsPicker) {
            BirthDatePickerSheet(date: $date)
        }
    }
}

private struct BirthDatePickerSheet: View {
    @Binding var date: Date?
    @Environment(\.dismiss) private var dismiss
    @State private var draft = BirthDate.suggested

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScreenTitle("Birth date", size: 32)

            Text(L("You must be 18 or older to join the Club."))
                .font(Afterglow.body(13))
                .foregroundStyle(Afterglow.muted)

            DatePicker("", selection: $draft, in: BirthDate.earliest...BirthDate.latest, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, AppLanguage.shared.locale)
                .frame(maxWidth: .infinity)

            PrimaryAction(title: "Done", icon: "checkmark") {
                date = draft
                dismiss()
            }
        }
        .padding(24)
        .onAppear { if let date { draft = date } }
        .presentationDetents([.medium])
        .presentationBackground(Afterglow.background)
    }
}
