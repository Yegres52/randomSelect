import 'package:flutter/material.dart';

import '../models/hero_role.dart';

Color roleColor(HeroRole role) {
  return switch (role) {
    HeroRole.tank => const Color(0xff316edb),
    HeroRole.damage => const Color(0xffd24040),
    HeroRole.healer => const Color(0xff34a853),
  };
}
