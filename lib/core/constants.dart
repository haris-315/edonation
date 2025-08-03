class Constants {
  static String emailTemplate(dynamic otp) => """<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Verify Your Email - Donation App</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f6f8fa;">

  <table align="center" width="100%" cellpadding="0" cellspacing="0" style="background-color: #f6f8fa; padding: 40px 0;">
    <tr>
      <td align="center">
        <table width="100%" max-width="600px" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; box-shadow: 0 0 10px rgba(0,0,0,0.05); padding: 30px;">

          <!-- Header -->
          <tr>
            <td align="center" style="padding-bottom: 20px;">
              <img src="https://img.icons8.com/color/96/charity.png" alt="Donation App" width="60" />
              <h2 style="margin: 10px 0; color: #333333;">Verify Your Email</h2>
              <p style="color: #777777; font-size: 14px; margin: 0;">Thank you for supporting a cause. Please verify your email address to continue.</p>
            </td>
          </tr>

          <!-- OTP Section -->
          <tr>
            <td align="center" style="padding: 30px 0;">
              <p style="color: #333333; font-size: 16px; margin: 0 0 10px;">Your One-Time Password (OTP) is:</p>
              <div style="font-size: 32px; letter-spacing: 10px; font-weight: bold; color: #1e88e5;">
                ${otp.toString()}               
              </div>
              <p style="color: #888888; font-size: 12px; margin-top: 10px;">This code will expire in 10 minutes.</p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding-top: 20px;">
              <p style="color: #999999; font-size: 12px;">If you did not request this email, please ignore it.</p>
              <p style="color: #999999; font-size: 12px;">&copy; 2025 DonationApp. All rights reserved.</p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>
""";

  static const superAdmin = "super@admin.com";
  static const adminPassword = "pass@Super";
  static const adminDocument = "super_admin";
}
