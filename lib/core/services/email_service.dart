import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmailService {
  final String _username = 'habimanamoise77@gmail.com';
  final String _password = 'pnnm pmfv ooyk dfud'; // App Password

  Future<void> sendPasswordResetEmail(String recipientEmail) async {
    final smtpServer = gmail(_username, _password);
    
    // In a real production app, this would be a deep link to reset the password.
    // For this prototype, we're simulating sending a reset code to their email.
    final resetCode = '123456'; 

    final message = Message()
      ..from = Address(_username, 'Umusaruro P2P')
      ..recipients.add(recipientEmail)
      ..subject = 'Umusaruro P2P - Password Reset'
      ..html = '''
        <div style="font-family: sans-serif; padding: 20px;">
          <h2>Password Reset Request</h2>
          <p>Hello,</p>
          <p>We received a request to reset your password for Umusaruro P2P.</p>
          <p>Your password reset code is: <strong>\$resetCode</strong></p>
          <p>If you did not request this, please ignore this email.</p>
          <br>
          <p>Best regards,<br>The Umusaruro Team</p>
        </div>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: \${sendReport.toString()}');
    } on MailerException catch (e) {
      print('Message not sent. \\n\${e.toString()}');
      for (var p in e.problems) {
        print('Problem: \${p.code}: \${p.msg}');
      }
      throw Exception('Failed to send email');
    }
  }

  Future<void> sendWelcomeEmail(String recipientEmail, String name) async {
    final smtpServer = gmail(_username, _password);
    
    final message = Message()
      ..from = Address(_username, 'Umusaruro P2P')
      ..recipients.add(recipientEmail)
      ..subject = 'Welcome to Umusaruro P2P!'
      ..html = '''
        <div style="font-family: sans-serif; padding: 20px;">
          <h2>Welcome aboard, \$name!</h2>
          <p>Thank you for registering on the Umusaruro P2P platform.</p>
          <p>We are thrilled to have you join our community of farmers and investors working together to revolutionize agriculture in Rwanda.</p>
          <p>If you have any questions, feel free to reach out to our support team.</p>
          <br>
          <p>Best regards,<br>The Umusaruro Team</p>
        </div>
      ''';

    try {
      await send(message, smtpServer);
    } catch (e) {
      print('Welcome email failed (non-critical): \$e');
    }
  }
}

final emailServiceProvider = Provider((ref) => EmailService());
