import Foundation
import Observation
import SwiftUI

/// App language. English keys are the source text; Turkish lives in `Translations.turkish`.
/// Views read `L(...)` inside `body`, so changing the language re-renders every screen.
@MainActor
@Observable
final class AppLanguage {
    enum Code: String { case en, tr }

    static let shared = AppLanguage()

    private static let storageKey = "appLanguage"

    private(set) var code: Code

    private init() {
        if let stored = UserDefaults.standard.string(forKey: Self.storageKey), let code = Code(rawValue: stored) {
            self.code = code
        } else {
            let device = Locale.preferredLanguages.first ?? "en"
            code = device.hasPrefix("tr") ? .tr : .en
        }
    }

    var isTurkish: Bool { code == .tr }

    var locale: Locale { Locale(identifier: isTurkish ? "tr_TR" : "en_US") }

    func select(_ code: Code) {
        guard code != self.code else { return }

        self.code = code
        UserDefaults.standard.set(code.rawValue, forKey: Self.storageKey)
    }

    func translate(_ key: String) -> String {
        isTurkish ? (Translations.turkish[key] ?? key) : key
    }

    /// Uppercases with the active language's rules (Turkish i → İ).
    func uppercase(_ text: String) -> String {
        text.uppercased(with: locale)
    }
}

/// Translates an English source string into the selected language.
@MainActor
func L(_ key: String) -> String {
    AppLanguage.shared.translate(key)
}

/// Translates a format string, then fills in its arguments.
@MainActor
func L(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: AppLanguage.shared.translate(key), locale: AppLanguage.shared.locale, arguments: arguments)
}

/// TR | EN switch used on the welcome screen and in Profile.
struct LanguageSwitch: View {
    private var language: AppLanguage { .shared }

    var body: some View {
        HStack(spacing: 2) {
            option("TR", .tr)
            option("EN", .en)
        }
        .padding(3)
        .background(Afterglow.background.opacity(0.62), in: Capsule())
        .overlay { Capsule().strokeBorder(Afterglow.ivory.opacity(0.35)) }
        .sensoryFeedback(ClubHaptics.selection, trigger: language.code)
    }

    private func option(_ title: String, _ code: AppLanguage.Code) -> some View {
        let selected = language.code == code

        return Button {
            language.select(code)
        } label: {
            Text(title)
                .font(Afterglow.medium(11.5, relativeTo: .caption))
                .tracking(0.6)
                .foregroundStyle(selected ? Afterglow.background : Afterglow.ivory)
                .frame(width: 38, height: 30)
                .background(selected ? Afterglow.ivory : .clear, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(code == .tr ? "Türkçe" : "English")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

enum Translations {
    static let turkish: [String: String] = [
        // Access
        "Sign up": "Kayıt ol",
        "Already a member? Sign in": "Zaten üye misin? Giriş yap",
        "Sign in": "Giriş yap",
        "Use your mobile number to continue.": "Devam etmek için cep telefonu numaranı kullan.",
        "Mobile number": "Cep telefonu",
        "Continue": "Devam",
        "Enter your code": "Kodunu gir",
        "We sent a %d-digit code to the email address on your membership. It stays valid for 15 minutes. Check your spam folder too.": "Üyeliğindeki e-posta adresine %d haneli bir kod gönderdik. Kod 15 dakika geçerli. Gelen kutusunda göremezsen spam klasörüne de bak.",
        "We sent a %d-digit code to +90 %@.": "+90 %2$@ numarasına %1$d haneli bir kod gönderdik.",
        "Test build: use code 1111.": "Test sürümü: 1111 kodunu kullan.",
        "No membership found for this number. Apply with Sign up.": "Bu numarayla bir üyelik bulunamadı. Kayıt ol ile başvurabilirsin.",
        "Your membership is still under review. We’ll share the decision soon.": "Üyeliğin hâlâ inceleniyor. Kararı yakında paylaşacağız.",
        "You appear to be offline.": "Çevrimdışı görünüyorsun.",
        "Can’t reach the server. Try again in a moment.": "Sunucuya ulaşılamıyor. Birazdan tekrar dene.",
        "Something went wrong. Try again.": "Bir şeyler ters gitti. Tekrar dene.",
        "Application error: %@": "Başvuru hatası: %@",
        "For this demo, use verification code 1111.": "Bu demoda doğrulama kodu olarak 1111 kullan.",
        "Verification code": "Doğrulama kodu",
        "Resend code": "Kodu yeniden gönder",
        "Change number": "Numarayı değiştir",
        "Verify & continue": "Doğrula ve devam et",
        "For this demo, enter 1111.": "Bu demoda 1111 gir.",
        "Back": "Geri",
        "Join the Club": "Kulübe katıl",
        "Three short steps. About a minute.": "Üç kısa adım. Yaklaşık bir dakika.",
        "About you": "Sen",
        "Your profile": "Profilin",
        "Finish": "Son",
        "Step %d of %d: %@": "Adım %d / %d: %@",
        "Submit application": "Başvuruyu gönder",
        "Full name": "Ad soyad",
        "Your name": "Adın",
        "Email": "E-posta",
        "University": "Üniversite",
        "Where did you study?": "Nerede okudun?",
        "Job title": "Meslek",
        "What do you do?": "Ne iş yapıyorsun?",
        "Height": "Boy",
        "Weight": "Kilo",
        "We use height and weight to plan activities that suit you.": "Boy ve kilo bilgini sana uygun etkinlikler planlamak için kullanıyoruz.",
        "Invitation code · optional": "Davet kodu · isteğe bağlı",
        "Have one? Enter it here": "Varsa buraya gir",
        "Instagram · optional": "Instagram · isteğe bağlı",
        "LinkedIn · optional": "LinkedIn · isteğe bağlı",
        "I confirm that I am 18 years old or older.": "18 yaşında veya daha büyük olduğumu onaylıyorum.",
        "Every application is reviewed by our team. We’ll email you the decision.": "Her başvuru ekibimiz tarafından incelenir. Kararı sana e-postayla ileteceğiz.",
        "We’ve received your application": "Başvurunu aldık",
        "We’re reviewing it.": "İnceliyoruz.",
        "Every application is reviewed by hand. We’ll share the decision when the review is complete.": "Her başvuru elle incelenir. İnceleme tamamlandığında kararı seninle paylaşacağız.",
        "Our team is reviewing it": "Ekibimiz inceliyor",
        "We’ll share the review decision with you": "İnceleme kararını seninle paylaşacağız",
        "Back to welcome": "Karşılamaya dön",

        // Tabs and shared
        "Events": "Etkinlikler",
        "Explore": "Keşfet",
        "My Events": "Etkinliklerim",
        "Club": "Club",
        "Profile": "Profil",
        "Save event": "Etkinliği kaydet",
        "Remove from saved events": "Kaydedilenlerden çıkar",
        "Done": "Bitti",
        "Cancel": "Vazgeç",
        "Language": "Dil",

        // Events
        "The Vubes calendar": "Vubes takvimi",
        "Find your next trail, session or weekend away.": "Bir sonraki parkurunu, seansını veya hafta sonu kaçamağını bul.",
        "All": "Tümü",
        "Sports": "Spor",
        "Camp": "Kamp",
        "Saved": "Kaydedilenler",
        "Filter": "Filtre",
        "Coming up": "Yaklaşan",
        "%d events": "%d etkinlik",
        "Capacity": "Kontenjan",
        "%d of %d spots taken": "%d / %d yer dolu",
        "%d spots left": "%d yer kaldı",
        "Last %d spots": "Son %d yer",
        "Fully booked": "Kontenjan doldu",
        "No saved events": "Kayıtlı etkinlik yok",
        "No matching events": "Eşleşen etkinlik yok",
        "Explore map": "Haritayı keşfet",
        "Featured experiences": "Öne çıkan deneyimler",
        "Confirmed": "Onaylandı",
        "Featured event %d of %d": "Öne çıkan etkinlik %d / %d",
        "View %@": "%@ etkinliğini görüntüle",
        "What to bring & meeting point": "Neler getirmeli ve buluşma noktası",
        "What to bring & stay details": "Neler getirmeli ve konaklama ayrıntıları",
        "Meeting point: %@": "Buluşma noktası: %@",
        "Organizer: %@": "Organizatör: %@",
        "In progress": "Devam ediyor",
        "Open activity map": "Etkinlik haritasını aç",
        "View event pass": "Etkinlik kartını gör",
        "Join event": "Etkinliğe katıl",
        "Itinerary": "Program",
        "%d sessions": "%d seans",
        "Day %d": "%d. Gün",
        "Sport": "Spor",
        "All sports": "Tüm sporlar",
        "Level": "Seviye",
        "All levels": "Tüm seviyeler",
        "Clear filters": "Filtreleri temizle",
        "Sport & level": "Spor ve seviye",

        // Explore and activity map
        "Istanbul": "İstanbul",
        "No matching events in Istanbul": "İstanbul’da eşleşen etkinlik yok",
        "Show %@": "%@ etkinliğini göster",
        "View event": "Etkinliği gör",
        "Show all matching events": "Eşleşen tüm etkinlikleri göster",
        "Activity map": "Etkinlik haritası",
        "Mediterranean": "Akdeniz",
        "%d participants": "%d katılımcı",
        "Reset participant selection": "Katılımcı seçimini sıfırla",
        "Sample locations": "Örnek konumlar",

        // My Events
        "Upcoming": "Yaklaşan",
        "Past": "Geçmiş",
        "Your confirmed bookings will appear here.": "Onaylanmış rezervasyonların burada görünecek.",
        "Happening now": "Şu an",
        "Event pass": "Etkinlik kartı",
        "Open event": "Etkinliği aç",
        "Open %@, in progress": "%@ aç, devam ediyor",
        "Illustrative pass": "Örnek kart",

        // Club
        "The people behind the sessions": "Seansların arkasındaki insanlar",
        "Meet the coaches, get to know their crews and see what members thought of their last sessions.": "Antrenörlerle tanış, ekiplerini keşfet ve üyelerin son seansları hakkında ne düşündüğünü gör.",
        "No trainers followed yet": "Henüz takip edilen antrenör yok",
        "Follow a trainer to find their crew and events here.": "Ekibini ve etkinliklerini burada bulmak için bir antrenörü takip et.",
        "Upcoming with %@": "%@ ile yaklaşanlar",
        "Rated experiences": "Puanlanan deneyimler",
        "All trainers": "Tüm antrenörler",
        "Following": "Takip ediliyor",
        "Crew": "Ekip",
        "Personal trainer": "Kişisel antrenör",
        "Follow trainer": "Antrenörü takip et",
        "Introduction requested": "Tanışma isteği gönderildi",
        "Request an introduction": "Tanışma iste",
        "Request introduction": "Tanışma iste",
        "Meet %@": "%@ ile tanış",
        "Save a demo request to connect with this trainer.": "Bu antrenörle bağlantı kurmak için demo bir istek kaydet.",
        "Member ratings": "Üye puanları",
        "· %d ratings": "· %d puan",
        "%@ out of 5, %d ratings": "5 üzerinden %@, %d puan",
        "Your rating": "Puanın",
        "Rate %d out of 5": "5 üzerinden %d ver",

        // Profile
        "Club member": "Club üyesi",
        "Account settings": "Hesap ayarları",
        "Privacy": "Gizlilik",
        "Sign out": "Çıkış yap",
        "That code isn’t right. Check it and try again.": "Kod doğru değil. Kontrol edip tekrar dene.",
        "That code has expired. Request a new one.": "Kodun süresi doldu. Yeni bir kod iste.",
        "Too many attempts. Please wait a few minutes and try again.": "Çok fazla deneme yapıldı. Birkaç dakika bekleyip tekrar dene.",
        "We couldn’t send your code right now. Try again in a moment.": "Kodu şu anda gönderemedik. Biraz sonra tekrar dene.",
        "A membership with this phone number or email already exists.": "Bu telefon numarası veya e-posta ile bir üyelik zaten var.",
        "That photo is too large. Choose a smaller one.": "Bu fotoğraf çok büyük. Daha küçük bir tane seç.",
        "Something went wrong on our side. Try again in a moment.": "Bir sorun oluştu. Biraz sonra tekrar dene.",
        "Saving…": "Kaydediliyor…",
        "Save changes": "Değişiklikleri kaydet",
        "Email updated.": "E-posta güncellendi.",
        "Phone number updated.": "Telefon numarası güncellendi.",
        "Close": "Kapat",
        "Contact details": "İletişim bilgileri",
        "Not added": "Eklenmedi",
        "We email a code to confirm every change.": "Her değişikliği onaylamak için e-postana bir kod göndeririz.",
        "Body details": "Beden bilgileri",
        "Clothing size": "Beden",
        "Not set": "Belirtilmedi",
        "Height must be 100–250 cm and weight 30–300 kg.": "Boy 100–250 cm, kilo 30–300 kg arasında olmalı.",
        "Birth date": "Doğum tarihi",
        "Your birth date can’t be changed. Contact support to correct it.": "Doğum tarihi sonradan değiştirilemez. Düzeltme için destekle iletişime geç.",
        "You can add your birth date once.": "Doğum tarihini bir kez ekleyebilirsin.",
        "Change": "Değiştir",
        "Saved.": "Kaydedildi.",
        "Change email": "E-postayı değiştir",
        "Change phone number": "Telefon numarasını değiştir",
        "We’ll send a code to the new address to confirm it.": "Onaylamak için yeni adrese bir kod göndereceğiz.",
        "We’ll send a code to the email address on your account to confirm the change.": "Değişikliği onaylamak için hesabındaki e-posta adresine bir kod göndereceğiz.",
        "New email address": "Yeni e-posta adresi",
        "New mobile number": "Yeni cep telefonu",
        "Sending…": "Gönderiliyor…",
        "Send code": "Kod gönder",
        "We sent a code to %@.": "%@ adresine bir kod gönderdik.",
        "We sent a code to the email address on your account.": "Hesabındaki e-posta adresine bir kod gönderdik.",
        "Verifying…": "Doğrulanıyor…",
        "Verify": "Doğrula",
        "Select your birth date": "Doğum tarihini seç",
        "Not selected": "Seçilmedi",
        "You must be 18 or older to join the Club.": "Kulübe katılmak için 18 yaşında veya daha büyük olmalısın.",
        "Drag and pinch to adjust": "Ayarlamak için sürükle ve yakınlaştır",
        "Use photo": "Fotoğrafı kullan",
        "Move and scale": "Taşı ve ölçekle",
        "That email address is already used by another membership.": "Bu e-posta adresi başka bir üyelikte kullanılıyor.",
        "That phone number is already used by another membership.": "Bu telefon numarası başka bir üyelikte kullanılıyor.",
        "The demo account’s contact details can’t be changed.": "Demo hesabının iletişim bilgileri değiştirilemez.",
        "Change photo": "Fotoğrafı değiştir",
        "Add photo": "Fotoğraf ekle",
        "Choose from library": "Kütüphaneden seç",
        "Remove photo": "Fotoğrafı kaldır",
        "Profile photo": "Profil fotoğrafı",
        "Updating photo…": "Fotoğraf güncelleniyor…",
        "We couldn’t use that photo. Try another one.": "Bu fotoğraf kullanılamadı. Başka bir tane dene.",
        "Ada Kaya · Club member": "Ada Kaya · Club üyesi",
        "Your profile is private. Activity maps use sample locations.": "Profilin gizli. Etkinlik haritaları örnek konumlar kullanır.",

        // Checkout and confirmation
        "Checkout": "Ödeme",
        "Your booking": "Rezervasyonun",
        "1 participant": "1 katılımcı",
        "Full day program": "Tam gün program",
        "Full %d-day program": "Tam %d günlük program",
        "Accommodation included": "Konaklama dahil",
        "Total": "Toplam",
        "I agree to the participation terms.": "Katılım koşullarını kabul ediyorum.",
        "Pay now": "Şimdi öde",
        "Processing…": "İşleniyor…",
        "Payment": "Ödeme",
        "Card number": "Kart numarası",
        "Name on card": "Karttaki isim",
        "Expiry": "Son kullanma",
        "Payments are coming soon. For now no card details are collected and nothing is charged.": "Ödeme altyapısı yakında devreye alınacak. Şimdilik kart bilgisi alınmaz ve ücret tahsil edilmez.",
        "We couldn’t complete your booking. Try again.": "Katılımın tamamlanamadı. Tekrar dene.",
        "Your registration has been received.": "Kaydınız alınmıştır.",
        "Show this code at the stand when you arrive.": "Etkinliğe geldiğinde bu kodu standda okut.",
        "Event QR code": "Etkinlik QR kodu",
        "Events you’ve attended will appear here.": "Katıldığın etkinlikler burada görünür.",
        "Bookings couldn’t be loaded": "Katılımların yüklenemedi",
        "Field check-in": "Saha girişi",
        "Allow camera access in Settings.": "Ayarlar’dan kamera erişimine izin ver.",
        "Scan member pass": "Üye kartını okut",
        "Point the camera at the member’s QR code.": "Kamerayı üyenin QR koduna çevir.",
        "Camera access is needed to scan passes.": "Kartları okutmak için kamera izni gerekir.",
        "Checked in": "Giriş yapıldı",
        "Already checked in": "Zaten giriş yapılmış",
        "Scan next": "Sıradakini okut",
        "This code isn’t valid for this event.": "Bu kod geçerli değil.",
        "You’re in.": "Katılımın tamam.",
        "Your booking is confirmed.": "Rezervasyonun onaylandı.",
        "Go to My Events": "Etkinliklerime git",

        // Sports, levels, locations, dates
        "Trail running": "Parkur koşusu",
        "Running": "Koşu",
        "Mobility": "Mobilite",
        "Hiking": "Doğa yürüyüşü",
        "Walking": "Yürüyüş",
        "Cycling": "Bisiklet",
        "Easy": "Kolay",
        "Moderate": "Orta",
        "Hard": "Zor",
        "Kaş & Istanbul": "Kaş ve İstanbul",
        "Today": "Bugün",
        "Nov 22–24": "22–24 Kas",
        "Nov 29": "29 Kas",
        "Dec 6": "6 Ara",
        "For you": "Senin için",
        "Your trainers": "PT’lerin",
        "Discover": "Keşfet",
        "Discover trainers": "PT’leri keşfet",
        "Your trainers’ next sessions, in one place.": "PT’lerinin sıradaki seansları tek yerde.",
        "Loading Club": "Club yükleniyor",
        "Club opens after your first booking": "Club, ilk katılımından sonra açılır",
        "Trainers, crews and ratings are available to members with a confirmed booking.": "PT’ler, ekipler ve puanlar onaylı katılımı olan üyelere açıktır.",
        "Club couldn’t be loaded": "Club yüklenemedi",
        "Check your connection and try again.": "Bağlantını kontrol edip tekrar dene.",
        "Try again": "Tekrar dene",
        "No trainers yet": "Henüz PT yok",
        "Follow a trainer, or ask the club to connect you with one.": "Bir PT’yi takip et ya da kulüpten seni bağlamasını iste.",
        "No upcoming events from your trainers yet.": "PT’lerinden yaklaşan etkinlik yok.",
        "No upcoming events yet.": "Henüz yaklaşan etkinlik yok.",
        "Trainer unavailable": "PT görüntülenemiyor",
        "This profile couldn’t be loaded.": "Bu profil yüklenemedi.",
        "Trainers couldn’t be loaded": "PT’ler yüklenemedi",
        "Loading events": "Etkinlikler yükleniyor",
        "Events couldn’t be loaded": "Etkinlikler yüklenemedi",
        "Hasdal Run & Meet": "Hasdal Koşu ve Buluşma",
        "Kağıthane, Istanbul": "Kağıthane, İstanbul",
        "Meet at the club": "Kulüpte buluşma",
        "Welcome & warm-up · 30 min": "Karşılama ve ısınma · 30 dk",
        "Group run": "Grup koşusu",
        "Easy-pace run around Hasdal · 1 hr": "Hasdal çevresinde rahat tempo koşu · 1 sa",
        "Coffee & get-together": "Kahve ve buluşma",
        "Meet the crew · 45 min": "Ekiple tanışma · 45 dk",
        "Yılmaz Ulusoy Atlı Spor Kulübü, Hasdal": "Yılmaz Ulusoy Atlı Spor Kulübü, Hasdal",
        "Bring running shoes, water and a light layer. Organized by Gürkan Bilgen.": "Koşu ayakkabısı, su ve ince bir kat getir. Düzenleyen: Gürkan Bilgen.",
        "Dec 13": "13 Ara",
        "Dec 14": "14 Ara",
        "Dec 20": "20 Ara",
        "Nov 8": "8 Kas",
        "Nov 2": "2 Kas",
        "Oct 26": "26 Eki",

        // Event titles and meeting details
        "Likya Trail & Mobility Camp": "Likya Trail ve Mobilite Kampı",
        "Likya Trail & Mobility": "Likya Trail ve Mobilite",
        "Belgrad Forest Run": "Belgrad Ormanı Koşusu",
        "Sunday Mobility": "Pazar Mobilite",
        "Bosphorus Ridge Hike": "Boğaz Sırtı Yürüyüşü",
        "Bosphorus Sunrise Ride": "Boğaz Gün Doğumu Turu",
        "Marmara Waterfront Walk": "Marmara Sahil Yürüyüşü",
        "Likya Coastal Run": "Likya Sahil Koşusu",
        "Forest Walk": "Orman Yürüyüşü",
        "Terrace Recovery": "Teras Toparlanma",
        "Coastal Trail Morning": "Sahil Parkuru Sabahı",
        "Belgrad Forest trailhead": "Belgrad Ormanı parkur girişi",
        "Club terrace": "Club terası",
        "Ridge trailhead": "Sırt parkuru girişi",
        "Bebek waterfront": "Bebek sahili",
        "Florya promenade": "Florya sahil yolu",
        "Bring trail shoes, water, a light layer and sun protection.": "Parkur ayakkabısı, su, ince bir kat ve güneş koruması getir.",
        "Bring a mat, water and comfortable layers.": "Mat, su ve rahat kıyafetler getir.",
        "Bring a roadworthy bicycle, helmet, lights and water.": "Yola uygun bir bisiklet, kask, ışık ve su getir.",
        "Bring comfortable walking shoes, water and a light layer.": "Rahat yürüyüş ayakkabısı, su ve ince bir kat getir.",
        "Two nights at the club’s lodge are included in the full program.": "Kulübün konaklama tesisinde iki gece, tam programa dahildir.",

        // Program sessions
        "Meet at Kaş Marina": "Kaş Marina’da buluşma",
        "Check-in · 30 min": "Kayıt · 30 dk",
        "Coastal trail run": "Sahil parkur koşusu",
        "Guided group run · 1 hr 30 min": "Rehberli grup koşusu · 1 sa 30 dk",
        "Mobility session": "Mobilite seansı",
        "Stretch & recover · 45 min": "Esneme ve toparlanma · 45 dk",
        "Lunch on the terrace": "Terasta öğle yemeği",
        "Group lunch · 1 hr": "Grup yemeği · 1 sa",
        "Trail technique clinic": "Parkur tekniği atölyesi",
        "Footwork and pacing · 45 min": "Ayak tekniği ve tempo · 45 dk",
        "Coastal cool-down": "Sahilde soğuma",
        "Easy walk & guided stretch · 45 min": "Hafif yürüyüş ve rehberli esneme · 45 dk",
        "Sunset debrief": "Gün batımı değerlendirmesi",
        "Terrace tea & tomorrow’s route · 30 min": "Teras çayı ve yarının rotası · 30 dk",
        "Breakfast": "Kahvaltı",
        "At the lodge · 45 min": "Konaklama tesisinde · 45 dk",
        "Lycian Way trail": "Likya Yolu parkuru",
        "Guided run · 2 hr": "Rehberli koşu · 2 sa",
        "Recovery & lunch": "Toparlanma ve öğle yemeği",
        "Mobility and a shared meal · 1 hr": "Mobilite ve ortak yemek · 1 sa",
        "Route-reading workshop": "Rota okuma atölyesi",
        "Navigation with Deniz · 45 min": "Deniz ile navigasyon · 45 dk",
        "Mobility reset": "Mobilite yenileme",
        "Guided recovery · 45 min": "Rehberli toparlanma · 45 dk",
        "Crew wind-down": "Ekip dinlenmesi",
        "Tea and trail stories · 30 min": "Çay ve parkur hikâyeleri · 30 dk",
        "Sunrise mobility": "Gün doğumu mobilitesi",
        "Terrace session · 45 min": "Teras seansı · 45 dk",
        "Coastal walk": "Sahil yürüyüşü",
        "Easy group walk · 1 hr": "Hafif grup yürüyüşü · 1 sa",
        "Lodge check-out": "Tesisten çıkış",
        "Pack & store bags · 30 min": "Toparlan ve çantaları bırak · 30 dk",
        "Lunch in Kaş": "Kaş’ta öğle yemeği",
        "Shared table · 1 hr": "Ortak sofra · 1 sa",
        "Your next trail": "Bir sonraki parkurun",
        "Personal training takeaways · 45 min": "Kişisel antrenman çıkarımları · 45 dk",
        "Club send-off": "Club uğurlaması",
        "Meet at Kaş Marina · 30 min": "Kaş Marina’da buluşma · 30 dk",
        "Meet at the trailhead": "Parkur girişinde buluşma",
        "Warm-up · 15 min": "Isınma · 15 dk",
        "Forest loop": "Orman turu",
        "Guided group run · 1 hr": "Rehberli grup koşusu · 1 sa",
        "Terrace mobility": "Teras mobilite",
        "Guided session · 1 hr": "Rehberli seans · 1 sa",
        "Ridge hike": "Sırt yürüyüşü",
        "Guided hike · 2 hr": "Rehberli yürüyüş · 2 sa",
        "Meet by the waterfront": "Sahilde buluşma",
        "Bike check · 15 min": "Bisiklet kontrolü · 15 dk",
        "Bosphorus ride": "Boğaz turu",
        "Guided group ride · 1 hr 30 min": "Rehberli grup turu · 1 sa 30 dk",
        "Coffee by the water": "Sahilde kahve",
        "Group cool-down · 30 min": "Grup soğuması · 30 dk",
        "Meet on the promenade": "Sahil yolunda buluşma",
        "Group introduction · 15 min": "Grup tanışması · 15 dk",
        "Walk along the coast": "Sahil boyu yürüyüş",
        "Recovery": "Toparlanma",
        "Forest walk": "Orman yürüyüşü",
        "Group hike · 1 hr": "Grup yürüyüşü · 1 sa",
        "Mobility practice": "Mobilite pratiği",
        "Guided movement · 1 hr": "Rehberli hareket · 1 sa",
        "Breathwork & tea": "Nefes çalışması ve çay",
        "Coastal loop": "Sahil turu",
        "Guided trail run · 90 min": "Rehberli parkur koşusu · 90 dk",
        "Recovery & stretch": "Toparlanma ve esneme",
        "Cool-down · 30 min": "Soğuma · 30 dk",

        // Trainers
        "Trail running & endurance": "Parkur koşusu ve dayanıklılık",
        "8 years coaching": "8 yıllık antrenörlük",
        "6 years coaching": "6 yıllık antrenörlük",
        "7 years coaching": "7 yıllık antrenörlük",
        "Deniz brings runners together on coastal and forest trails. His sessions pair steady pacing with practical trail technique and time to recover.": "Deniz, koşucuları sahil ve orman parkurlarında buluşturuyor. Seansları istikrarlı tempoyu pratik parkur tekniği ve toparlanma zamanıyla bir araya getiriyor.",
        "Coastal Crew": "Sahil Ekibi",
        "Mobility & recovery": "Mobilite ve toparlanma",
        "Ece coaches small groups through mobility, breathwork and recovery. Her sessions welcome members looking to move more comfortably at their own pace.": "Ece, küçük grupları mobilite, nefes çalışması ve toparlanma konusunda çalıştırıyor. Seansları, kendi temposunda daha rahat hareket etmek isteyen üyeleri karşılıyor.",
        "Sunday Studio": "Pazar Stüdyosu",
        "Hiking & outdoor conditioning": "Doğa yürüyüşü ve açık hava kondisyonu",
        "Mert leads forest walks and ridge hikes. He shares route preparation, outdoor skills and conditioning tips throughout the day.": "Mert, orman yürüyüşlerine ve sırt turlarına liderlik ediyor. Gün boyunca rota hazırlığı, açık hava becerileri ve kondisyon ipuçları paylaşıyor.",
        "Forest Circle": "Orman Çemberi"
    ]
}
