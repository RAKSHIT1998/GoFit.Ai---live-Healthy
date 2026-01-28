import nodemailer from 'nodemailer';
import OpenAI from 'openai';

// Create reusable transporter
const createTransporter = () => {
  // Use environment variables for email configuration
  // For production, use SMTP settings (Gmail, SendGrid, etc.)
  // For development, you can use Ethereal Email (https://ethereal.email)
  
  if (process.env.NODE_ENV === 'production') {
    return nodemailer.createTransport({
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.SMTP_PORT || '587'),
      secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASSWORD
      }
    });
  } else {
    // Development: Use Ethereal Email (creates test account automatically)
    // Or use Gmail with App Password
    return nodemailer.createTransport({
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.SMTP_PORT || '587'),
      secure: false,
      auth: {
        user: process.env.SMTP_USER || process.env.GMAIL_USER,
        pass: process.env.SMTP_PASSWORD || process.env.GMAIL_APP_PASSWORD
      }
    });
  }
};

// Email templates
const emailTemplates = {
  welcome: ({ name }) => ({
    subject: 'Welcome to GoFit.Ai! 🎉',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Welcome to GoFit.Ai</title>
      </head>
      <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
          <h1 style="color: white; margin: 0;">Welcome to GoFit.Ai! 🎉</h1>
        </div>
        <div style="background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px;">
          <p style="font-size: 16px; margin-top: 0;">Hi ${name || 'there'},</p>
          <p style="font-size: 16px;">We're thrilled to have you join the GoFit.Ai community! You're now on your way to achieving your health and fitness goals.</p>
          
          <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #667eea;">
            <h2 style="margin-top: 0; color: #667eea;">What's Next?</h2>
            <ul style="padding-left: 20px;">
              <li>📸 <strong>Scan your meals</strong> - Use our AI-powered meal scanner to track your nutrition</li>
              <li>💪 <strong>Get personalized workouts</strong> - Receive AI-generated workout recommendations</li>
              <li>⏰ <strong>Track your fasting</strong> - Monitor your intermittent fasting progress</li>
              <li>📊 <strong>View your progress</strong> - See your health metrics and achievements</li>
            </ul>
          </div>
          
          <p style="font-size: 16px;">You're starting with a <strong>3-day free trial</strong> to explore all premium features. Enjoy!</p>
          
          <div style="text-align: center; margin: 30px 0;">
            <a href="${process.env.APP_URL || 'https://gofitai.org'}" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px;">Get Started</a>
          </div>
          
          <p style="font-size: 14px; color: #666; margin-top: 30px;">If you have any questions, feel free to reach out to our support team.</p>
          <p style="font-size: 14px; color: #666; margin: 0;">Happy tracking!<br>The GoFit.Ai Team</p>
        </div>
      </body>
      </html>
    `,
    text: `
      Welcome to GoFit.Ai!
      
      Hi ${name || 'there'},
      
      We're thrilled to have you join the GoFit.Ai community! You're now on your way to achieving your health and fitness goals.
      
      What's Next?
      - Scan your meals - Use our AI-powered meal scanner to track your nutrition
      - Get personalized workouts - Receive AI-generated workout recommendations
      - Track your fasting - Monitor your intermittent fasting progress
      - View your progress - See your health metrics and achievements
      
      You're starting with a 3-day free trial to explore all premium features. Enjoy!
      
      Get started: ${process.env.APP_URL || 'https://gofitai.org'}
      
      If you have any questions, feel free to reach out to our support team.
      
      Happy tracking!
      The GoFit.Ai Team
    `
  }),

  forgotPassword: ({ name, resetLink }) => ({
    subject: 'Reset Your GoFit.Ai Password',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Reset Your Password</title>
      </head>
      <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
          <h1 style="color: white; margin: 0;">Reset Your Password</h1>
        </div>
        <div style="background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px;">
          <p style="font-size: 16px; margin-top: 0;">Hi ${name || 'there'},</p>
          <p style="font-size: 16px;">We received a request to reset your password for your GoFit.Ai account.</p>
          
          <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #667eea;">
            <p style="margin: 0; font-size: 16px;">Click the button below to reset your password:</p>
          </div>
          
          <div style="text-align: center; margin: 30px 0;">
            <a href="${resetLink}" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px;">Reset Password</a>
          </div>
          
          <p style="font-size: 14px; color: #666;">Or copy and paste this link into your browser:</p>
          <p style="font-size: 12px; color: #999; word-break: break-all; background: white; padding: 10px; border-radius: 4px;">${resetLink}</p>
          
          <p style="font-size: 14px; color: #666; margin-top: 30px;">This link will expire in <strong>1 hour</strong> for security reasons.</p>
          <p style="font-size: 14px; color: #666;">If you didn't request a password reset, please ignore this email or contact support if you have concerns.</p>
          
          <p style="font-size: 14px; color: #666; margin-top: 30px;">Best regards,<br>The GoFit.Ai Team</p>
        </div>
      </body>
      </html>
    `,
    text: `
      Reset Your Password
      
      Hi ${name || 'there'},
      
      We received a request to reset your password for your GoFit.Ai account.
      
      Click the link below to reset your password:
      ${resetLink}
      
      This link will expire in 1 hour for security reasons.
      
      If you didn't request a password reset, please ignore this email or contact support if you have concerns.
      
      Best regards,
      The GoFit.Ai Team
    `
  })
};

// Generate a premium subscription thank-you email.
// If OPENAI_API_KEY is configured, we generate copy using AI; otherwise we use a solid fallback template.
const generateSubscriptionThankYou = async ({ name, plan, price, renewDate }) => {
  const safeName = name || 'there';
  const safePlan = plan === 'yearly' ? 'Yearly' : 'Monthly';
  const safePrice = price || (plan === 'yearly' ? '$19.99/year' : '$1.99/month');
  const safeRenewDate = renewDate || '';

  const OPENAI_API_KEY = (process.env.OPENAI_API_KEY || '').trim();
  const openai = OPENAI_API_KEY ? new OpenAI({ apiKey: OPENAI_API_KEY }) : null;

  // Fallback (no AI)
  const fallback = {
    subject: `Thank you for subscribing to GoFit.Ai (${safePlan})`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Thank you for subscribing</title>
      </head>
      <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
          <h1 style="color: white; margin: 0;">Thank you for subscribing! 🎉</h1>
        </div>
        <div style="background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px;">
          <p style="font-size: 16px; margin-top: 0;">Hi ${safeName},</p>
          <p style="font-size: 16px;">Thanks for upgrading to <strong>GoFit.Ai Premium</strong>. Your <strong>${safePlan}</strong> plan is now active.</p>
          <div style="background: white; padding: 16px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #667eea;">
            <p style="margin: 0; font-size: 15px;"><strong>Plan:</strong> ${safePlan}</p>
            <p style="margin: 6px 0 0; font-size: 15px;"><strong>Price:</strong> ${safePrice}</p>
            ${safeRenewDate ? `<p style="margin: 6px 0 0; font-size: 15px;"><strong>Next renewal:</strong> ${safeRenewDate}</p>` : ''}
          </div>
          <p style="font-size: 16px;">You now have full access to premium features including personalized workouts, meal recommendations, and advanced tracking.</p>
          <div style="text-align: center; margin: 28px 0;">
            <a href="${process.env.APP_URL || 'https://gofitai.org'}" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 14px 26px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px;">Open GoFit.Ai</a>
          </div>
          <p style="font-size: 14px; color: #666; margin-top: 30px;">Need help? Reply to this email and we’ll assist you.</p>
          <p style="font-size: 14px; color: #666; margin: 0;">The GoFit.Ai Team</p>
        </div>
      </body>
      </html>
    `,
    text: `
Thank you for subscribing!

Hi ${safeName},

Thanks for upgrading to GoFit.Ai Premium. Your ${safePlan} plan is now active.

Plan: ${safePlan}
Price: ${safePrice}
${safeRenewDate ? `Next renewal: ${safeRenewDate}\n` : ''}

You now have full access to premium features.

Open GoFit.Ai: ${process.env.APP_URL || 'https://gofitai.org'}

The GoFit.Ai Team
    `.trim()
  };

  if (!openai) return fallback;

  try {
    const prompt = `
Write a short, friendly subscription thank-you email for a fitness app called GoFit.Ai.
User name: ${safeName}
Plan: ${safePlan}
Price: ${safePrice}
${safeRenewDate ? `Next renewal date: ${safeRenewDate}` : ''}

Return JSON with keys: subject, html, text.
HTML should be simple and readable (no external images).
`.trim();

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.7
    });

    const content = completion.choices?.[0]?.message?.content || '';
    const parsed = JSON.parse(content);
    if (parsed?.subject && parsed?.html && parsed?.text) return parsed;
    return fallback;
  } catch (e) {
    console.warn('⚠️ AI thank-you email generation failed, using fallback:', e?.message || e);
    return fallback;
  }
};

// Send email function
export const sendEmail = async (to, template, data) => {
  try {
    const transporter = createTransporter();
    
    // Get email template - pass data as an object with named properties
    // This ensures consistency across all template functions
    const templateData = typeof data === 'string' 
      ? { name: data }  // Handle legacy case where data might be just a string (name)
      : data;           // Otherwise use the data object as-is
    
    const emailContent = emailTemplates[template](templateData);
    
    const mailOptions = {
      from: process.env.SMTP_FROM || `"GoFit.Ai" <${process.env.SMTP_USER || 'noreply@gofitai.org'}>`,
      to: to,
      subject: emailContent.subject,
      html: emailContent.html,
      text: emailContent.text
    };
    
    const info = await transporter.sendMail(mailOptions);
    console.log('✅ Email sent successfully:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('❌ Error sending email:', error);
    return { success: false, error: error.message };
  }
};

// Subscription thank-you email (async because it can be AI-generated)
export const sendSubscriptionThankYouEmail = async (to, data) => {
  try {
    const transporter = createTransporter();
    const content = await generateSubscriptionThankYou(data || {});

    const mailOptions = {
      from: process.env.SMTP_FROM || `"GoFit.Ai" <${process.env.SMTP_USER || 'noreply@gofitai.org'}>`,
      to,
      subject: content.subject,
      html: content.html,
      text: content.text
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('✅ Subscription thank-you email sent:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('❌ Error sending subscription thank-you email:', error);
    return { success: false, error: error.message };
  }
};

// Verify email configuration
export const verifyEmailConfig = async () => {
  try {
    const transporter = createTransporter();
    await transporter.verify();
    console.log('✅ Email server is ready to send messages');
    return true;
  } catch (error) {
    console.error('❌ Email server configuration error:', error);
    return false;
  }
};
