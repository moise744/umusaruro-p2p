import 'package:flutter/material.dart';

class MockProject {
  final String id;
  final String title;
  final String farmerName;
  final String cropType;
  final String location;
  final double targetAmount;
  final double raisedAmount;
  final double returnRate;
  final int durationMonths;
  final String status;
  final IconData imageIcon;

  const MockProject({
    required this.id,
    required this.title,
    required this.farmerName,
    required this.cropType,
    required this.location,
    required this.targetAmount,
    required this.raisedAmount,
    required this.returnRate,
    required this.durationMonths,
    required this.status,
    required this.imageIcon,
  });

  double get fundingPercent => (raisedAmount / targetAmount).clamp(0, 1);
  String get formattedTarget =>
      'RWF ${targetAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  String get formattedRaised =>
      'RWF ${raisedAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

class MockInvestment {
  final String id;
  final String projectTitle;
  final String cropType;
  final double amount;
  final double returnRate;
  final String status;
  final String date;

  const MockInvestment({
    required this.id,
    required this.projectTitle,
    required this.cropType,
    required this.amount,
    required this.returnRate,
    required this.status,
    required this.date,
  });
}

class MockNotification {
  final String id;
  final String title;
  final String body;
  final String time;
  final bool isRead;
  final String type;

  const MockNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.type,
  });
}

final mockProjects = [
  const MockProject(
    id: '1',
    title: 'Seasonal Maize Farm – Musanze',
    farmerName: 'Kagabo Jean',
    cropType: 'Maize',
    location: 'Musanze, Northern Province',
    targetAmount: 2500000,
    raisedAmount: 1750000,
    returnRate: 18,
    durationMonths: 4,
    status: 'active',
    imageIcon: Icons.agriculture,
  ),
  const MockProject(
    id: '2',
    title: 'Coffee Plantation Expansion',
    farmerName: 'Uwimana Alice',
    cropType: 'Coffee',
    location: 'Huye, Southern Province',
    targetAmount: 5000000,
    raisedAmount: 3200000,
    returnRate: 22,
    durationMonths: 8,
    status: 'active',
    imageIcon: Icons.local_cafe,
  ),
  const MockProject(
    id: '3',
    title: 'Irish Potato – Nyamagabe',
    farmerName: 'Habimana Pierre',
    cropType: 'Potatoes',
    location: 'Nyamagabe, Southern Province',
    targetAmount: 1800000,
    raisedAmount: 1800000,
    returnRate: 15,
    durationMonths: 3,
    status: 'completed',
    imageIcon: Icons.agriculture,
  ),
  const MockProject(
    id: '4',
    title: 'Avocado Orchard – Rwamagana',
    farmerName: 'Mukamana Grace',
    cropType: 'Avocado',
    location: 'Rwamagana, Eastern Province',
    targetAmount: 4000000,
    raisedAmount: 800000,
    returnRate: 25,
    durationMonths: 12,
    status: 'pending',
    imageIcon: Icons.eco,
  ),
  const MockProject(
    id: '5',
    title: 'Tea Farming – Nyamasheke',
    farmerName: 'Niyonsaba Eric',
    cropType: 'Tea',
    location: 'Nyamasheke, Western Province',
    targetAmount: 3500000,
    raisedAmount: 2100000,
    returnRate: 20,
    durationMonths: 6,
    status: 'active',
    imageIcon: Icons.local_cafe,
  ),
  const MockProject(
    id: '6',
    title: 'Bean & Tomato Intercrop – Bugesera',
    farmerName: 'Nzabonimpa Thomas',
    cropType: 'Beans',
    location: 'Bugesera, Eastern Province',
    targetAmount: 1200000,
    raisedAmount: 600000,
    returnRate: 16,
    durationMonths: 3,
    status: 'active',
    imageIcon: Icons.eco,
  ),
];

final mockInvestments = [
  const MockInvestment(
    id: '1',
    projectTitle: 'Seasonal Maize Farm – Musanze',
    cropType: 'Maize',
    amount: 500000,
    returnRate: 18,
    status: 'active',
    date: 'Mar 15, 2026',
  ),
  const MockInvestment(
    id: '2',
    projectTitle: 'Coffee Plantation Expansion',
    cropType: 'Coffee',
    amount: 1000000,
    returnRate: 22,
    status: 'active',
    date: 'Feb 20, 2026',
  ),
  const MockInvestment(
    id: '3',
    projectTitle: 'Irish Potato – Nyamagabe',
    cropType: 'Potatoes',
    amount: 300000,
    returnRate: 15,
    status: 'completed',
    date: 'Jan 10, 2026',
  ),
];

final mockNotifications = [
  const MockNotification(
    id: '1',
    title: 'Investment Confirmed',
    body: 'Your investment of RWF 500,000 in Maize Farm has been confirmed.',
    time: '2 hours ago',
    isRead: false,
    type: 'investment',
  ),
  const MockNotification(
    id: '2',
    title: 'Harvest Report Submitted',
    body: 'Kagabo Jean has submitted a harvest report for review.',
    time: '1 day ago',
    isRead: false,
    type: 'harvest',
  ),
  const MockNotification(
    id: '3',
    title: 'Profile Verified',
    body: 'Your farmer profile has been verified by the review team.',
    time: '3 days ago',
    isRead: true,
    type: 'verification',
  ),
  const MockNotification(
    id: '4',
    title: 'Project Fully Funded',
    body: 'Coffee Plantation Expansion has reached 100% funding.',
    time: '1 week ago',
    isRead: true,
    type: 'funding',
  ),
];
