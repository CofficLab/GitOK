import Foundation
import Testing

@Suite("AvatarIdentityRulesTests")
struct AvatarIdentityRulesTests {
    @Test("Email normalization and cache key follow app rules")
    func emailNormalizationAndCacheKeyFollowAppRules() {
        #expect(AvatarIdentityRules.normalizeEmail("  Ada@Example.COM \n") == "ada@example.com")
        #expect(AvatarIdentityRules.cacheKey(name: "ada", email: "  ") == "ada")
        #expect(AvatarIdentityRules.cacheKey(name: "ada", email: " Ada@Example.COM ") == "ada@example.com")
    }

    @Test("Gravatar URL uses normalized md5 and identicon fallback")
    func gravatarURLUsesNormalizedMD5AndIdenticonFallback() {
        let url = AvatarIdentityRules.gravatarURL(email: "MyEmailAddress@example.com ", size: 80)

        #expect(url.absoluteString == "https://www.gravatar.com/avatar/0bc83cb571cd1c50ba6f3e8a78ef1346?s=80&d=identicon")
    }

    @Test("Bot avatar detection supports noreply format and known bot names")
    func botAvatarDetectionSupportsNoreplyFormatAndKnownBotNames() {
        #expect(AvatarIdentityRules.botAvatarURL(email: "12345+dependabot[bot]@users.noreply.github.com", name: "")?.absoluteString == "https://github.com/dependabot.png")
        #expect(AvatarIdentityRules.botAvatarURL(email: "", name: "github-actions[bot]")?.absoluteString == "https://github.com/github-actions.png")
        #expect(AvatarIdentityRules.botAvatarURL(email: "ada@example.com", name: "ada") == nil)
    }
}
