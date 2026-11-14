import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../pages/common/coming_soon_page.dart';
import 'route_names.dart';
import '../../pages/chat/chat_page.dart';
import '../../pages/offers/offers_page.dart';
import '../../pages/members/members_page.dart';
import '../../pages/profile/profile_page.dart';
import '../../pages/members/member_card_page.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/auth/login_success_page.dart';
import '../../pages/news/news_page.dart';
import '../../pages/overview/overview_page.dart';
import '../../pages/membership/membership_page.dart';
import '../../pages/members/membership_required_page.dart';
import '../../pages/admin/admin_home_page.dart';
import '../../pages/admin/admin_chapters_page.dart';
import '../../pages/admin/admin_chapter_form_page.dart';
import '../../pages/admin/admin_member_form_page.dart';
import '../../pages/admin/admin_event_form_page.dart';
import '../../pages/admin/admin_news_form_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.chat,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const ChatPage()),
    GoRoute(
      path: '/home',
      builder: (context, state) => const ComingSoonPage(title: 'ILYF Overview'),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/login-success',
      builder: (context, state) => const LoginSuccessPage(),
    ),
    GoRoute(
      path: '/overview',
      builder: (context, state) => const OverviewPage(),
    ),
    GoRoute(path: '/members', builder: (context, state) => const MembersPage()),
    GoRoute(
      path: '/members/:id',
      builder: (context, state) =>
          MemberCardPage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/membership-required',
      builder: (context, state) => const MembershipRequiredPage(),
    ),
    GoRoute(
      path: '/membership',
      builder: (context, state) => const MembershipPage(),
    ),
    GoRoute(path: '/offers', builder: (context, state) => const OffersPage()),
    GoRoute(path: '/news', builder: (context, state) => const NewsPage()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminHomePage()),
    GoRoute(
      path: '/admin/chapters',
      builder: (context, state) => const AdminChaptersPage(),
    ),
    GoRoute(
      path: '/admin/chapters/new',
      builder: (context, state) => const AdminChapterFormPage(),
    ),
    GoRoute(
      path: '/admin/chapters/:id',
      builder: (context, state) =>
          AdminChapterFormPage(id: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/admin/members/new',
      builder: (context, state) => AdminMemberFormPage(
        chapterId: state.uri.queryParameters['chapterId'],
      ),
    ),
    GoRoute(
      path: '/admin/members/:id/edit',
      builder: (context, state) =>
          AdminMemberFormPage(id: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/events/new',
      builder: (context, state) => const AdminEventFormPage(),
    ),
    GoRoute(
      path: '/events/:id/edit',
      builder: (context, state) =>
          AdminEventFormPage(id: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/news/new',
      builder: (context, state) => const AdminNewsFormPage(),
    ),
    GoRoute(
      path: '/news/:id/edit',
      builder: (context, state) =>
          AdminNewsFormPage(id: state.pathParameters['id']),
    ),
    GoRoute(path: '/events', redirect: (context, state) => '/news'),
    GoRoute(path: '/admin/members', redirect: (context, state) => '/members'),
    GoRoute(
      path: '/view-more',
      redirect: (context, state) => '/login?next=/members',
    ),
    GoRoute(path: '/logged-in', redirect: (context, state) => '/members'),
    GoRoute(path: '/chapters', redirect: (context, state) => '/members'),
  ],
  errorBuilder: (context, state) =>
      const Scaffold(body: Center(child: Text('Page not found'))),
);
