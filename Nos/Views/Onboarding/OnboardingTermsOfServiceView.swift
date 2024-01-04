//
//  OnboardingTermsOfServiceView.swift
//  Nos
//
//  Created by Shane Bielefeld on 3/16/23.
//

import Dependencies
import SwiftUI

struct OnboardingTermsOfServiceView: View {
    @EnvironmentObject var state: OnboardingState
    @Environment(CurrentUser.self) var currentUser

    @Dependency(\.crashReporting) private var crashReporting
    
    /// Completion to be called when all onboarding steps are complete
    let completion: @MainActor () -> Void
    
    var body: some View {
        VStack {
            PlainText(.localizable.termsOfServiceTitle)
                .font(.custom("ClarityCity-Bold", size: 34, relativeTo: .largeTitle))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "#F08508"),
                            Color(hex: "#F43F75")
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                    .blendMode(.normal)
                )
                .padding(.top, 92)
                .padding(.bottom, 60)
            ScrollView {
                Text(termsOfService)
                    .foregroundColor(.secondaryTxt)
                Rectangle().fill(Color.clear)
                    .frame(height: 100)
            }
            .mask(
                VStack(spacing: 0) {
                    Rectangle().fill(Color.black)
                    LinearGradient(
                        colors: [Color.black, Color.black.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .padding(.horizontal, 44.5)
            HStack {
                BigActionButton(title: .localizable.reject) {
                    state.step = .onboardingStart
                }
                Spacer(minLength: 15)
                BigActionButton(title: .localizable.accept) {
                    switch state.flow {
                    case .createAccount:
                        do {
                            try await currentUser.createAccount()
                            completion()
                        } catch {
                            crashReporting.report(error)
                        }
                    case .loginToExistingAccount:
                        state.step = .login
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .background(Color.appBg)
        .navigationBarHidden(true)
    }
}

// swiftlint:disable line_length
// We don't localize these for legal reasons
fileprivate let termsOfService = """
    Summary
    This top section summarizes the terms below. This summary is provided to help your understanding of the terms, but be sure to read the entire document, because when you agree to it, you are indicating you accept all of the terms, not just this summary.
    
    Nos cloud services (the "Services") are a suite of services provided to you by Verse Communications Inc.
    The Services are provided "as is" and there are no warranties of any kind. There are significant limits on Verse's liability for any damages arising from your use of the Services.
    Terms of Service
    Introduction

    These Terms of Service ("Terms") govern your use of Nos cloud services, a suite of online services provided by Verse (the "Services").

    Nos Accounts

    In order to use some of the Services, you'll need to connect using your nostr identity. During onboarding, this identity will be created and used to connect to all Nos services. You are responsible for keeping your cryptographic identity confidential and for the activity that happens through your Nos account. Verse is not responsible for any losses arising out of unauthorized use of your Nos account.

    Services

    (a) Nos Relay act as a store and forward relay for your posts so your followers can get them when you're not running the application on your phone. .

    (b) Nos Notification Service looks at the posts of your friends which are on the pub's and not encrypted to tell your client to look for new updates

    Privacy Policy

    We use the information we receive through the Services as described in our Nos Privacy Policy. Our Privacy Notices describe in more detail the data we receive from each service:

    Communications

    We send periodic messages to help you get the most from your Nos Account. You may receive these in-product or to the address you signed-up with; they cover onboarding, different Nos Account services, and related offers and surveys. You may also choose to receive other types of email messages.

    You can change your email subscriptions with Verse from our emails (click the link at the bottom) or from the application.

    We may also send you important account information such as updates to legal or privacy terms, or security messages like phone number verification, email verification, and linked devices. These are necessary to our services and cannot be unsubscribed from. You can contact Verse at Verse Communications Attn: Versef – Legal Notices 9450 SW Gemini Dr PMB 21667
    Beverton Oregon 97008-7105 or contact@verse.app

    Your Content in Our Services

    You may upload content to Verse as part of the features of the Services. By uploading content, you hereby grant us a nonexclusive, royalty-free, worldwide license to use your content in connection with the provision of the Services. You hereby represent and warrant that your content will not infringe the rights of any third party and will comply with any content guidelines presented by Verse. Report claims of copyright or trademark infringement at planetarysupport.zendesk.com. To report abusive Screenshots, email us a link to the shot at contact@verse.app.

    Verse's Proprietary Rights

    Verse does not grant you any intellectual property rights in the Services that are not specifically stated in these Terms. For example, these Terms do not provide the right to use any of Verse's copyrights, trade names, trademarks, service marks, logos, domain names, or other distinctive brand features.

    Term; Termination

    These Terms will continue to apply until ended by either you or Verse. You can choose to end them at any time for any reason by deleting your Nos account, discontinuing your use of the Services, and if applicable, unsubscribing from our emails.

    We may suspend or terminate your access to the Services at any time for any reason, including, but not limited to, if we reasonably believe: (i) you have violated these Terms, (ii) you create risk or possible legal exposure for us; or (iii) our provision of the Services to you is no longer commercially viable. We will make reasonable efforts to notify you by the email address or phone number associated with your Nos account or the next time you attempt to access the Services.

    In all such cases, these Terms shall terminate, including, without limitation, your license to use the Services, except that the following sections shall continue to apply: Indemnification, Disclaimer; Limitation of Liability, Miscellaneous.

    Indemnification

    You agree to defend, indemnify and hold harmless Verse, its contractors, contributors, licensors, and partners, and their respective directors, officers, employees and agents ("Indemnified Parties") from and against any and all third party claims and expenses, including attorneys' fees, arising out of or related to your use of the Services (including, but not limited to, from any content uploaded by you).

    Disclaimer; Limitation of Liability

    THE SERVICES ARE PROVIDED "AS IS" WITH ALL FAULTS. TO THE EXTENT PERMITTED BY LAW, VERSE AND THE INDEMNIFIED PARTIES HEREBY DISCLAIM ALL WARRANTIES, WHETHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION WARRANTIES THAT THE SERVICES ARE FREE OF DEFECTS, MERCHANTABLE, FIT FOR A PARTICULAR PURPOSE, AND NON-INFRINGING. YOU BEAR THE ENTIRE RISK AS TO SELECTING THE SERVICES FOR YOUR PURPOSES AND AS TO THE QUALITY AND PERFORMANCE OF THE SERVICES, INCLUDING WITHOUT LIMITATION THE RISK THAT YOUR CONTENT IS DELETED OR CORRUPTED OR THAT SOMEONE ELSE ACCESSES YOUR ONLINE ACCOUNTS. THIS LIMITATION WILL APPLY NOTWITHSTANDING THE FAILURE OF ESSENTIAL PURPOSE OF ANY REMEDY. SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OR LIMITATION OF IMPLIED WARRANTIES, SO THIS DISCLAIMER MAY NOT APPLY TO YOU.

    EXCEPT AS REQUIRED BY LAW, VERSE AND THE INDEMNIFIED PARTIES WILL NOT BE LIABLE FOR ANY INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES ARISING OUT OF OR IN ANY WAY RELATING TO THESE TERMS OR THE USE OF OR INABILITY TO USE THE SERVICES, INCLUDING WITHOUT LIMITATION DIRECT AND INDIRECT DAMAGES FOR LOSS OF GOODWILL, WORK STOPPAGE, LOST PROFITS, LOSS OF DATA, AND COMPUTER FAILURE OR MALFUNCTION, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES AND REGARDLESS OF THE THEORY (CONTRACT, TORT, OR OTHERWISE) UPON WHICH SUCH CLAIM IS BASED. THE COLLECTIVE LIABILITY OF VERSE AND THE INDEMNIFIED PARTIES UNDER THIS AGREEMENT WILL NOT EXCEED $500 (FIVE HUNDRED DOLLARS). SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OR LIMITATION OF INCIDENTAL, CONSEQUENTIAL, OR SPECIAL DAMAGES, SO THIS EXCLUSION AND LIMITATION MAY NOT APPLY TO YOU.

    Modifications to these Terms

    Verse may update these Terms from time to time to address a new feature of the Services or to clarify a provision. The updated Terms will be posted online. If the changes are substantive, we will announce the update through Verse's usual channels for such announcements, such as blog posts and forums. Your continued use of the Services after the effective date of such changes constitutes your acceptance of such changes. To make your review more convenient, we will post an effective date at the top of this page.

    Miscellaneous

    These Terms constitute the entire agreement between you and Verse concerning the Services and are governed by the laws of the state of Oregon, U.S.A., excluding its conflict of law provisions. If any portion of these Terms is held to be invalid or unenforceable, the remaining portions will remain in full force and effect. In the event of a conflict between a translated version of these terms and the English language version, the English language version shall control.

     

    CONTACT US

    In order to resolve a complaint regarding the Site or to receive further information regarding use of the Site, please contact us at:

    Verse Communications Inc

    9450 SW Gemini Dr PMB 21667
    Beverton Oregon 97008-7105

    United States

    help@nos.social
    """
    
// swiftlint:enable line_length
