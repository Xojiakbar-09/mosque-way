enum Madhhab {
  hanafi('Hanafiy', 1),
  shafii('Shofi’iy', 0),
  maliki('Molikiy', 0),
  hanbali('Hanbaliy', 0);

  const Madhhab(this.label, this.school);
  final String label;
  final int school;
}
