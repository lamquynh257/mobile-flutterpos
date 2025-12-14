import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../menu_filterer.dart';
import './menu_form.dart';
import '../../common/common.dart';
import '../../provider/src.dart';
import '../popup_del.dart';
import '../avatar.dart';
import 'custom_scaffold.dart';

const _animDuration = Duration(milliseconds: 500);

class EditMenuScreen extends StatefulWidget {
  @override
  EditMenuScreenState createState() => EditMenuScreenState();
}

class EditMenuScreenState extends State<EditMenuScreen> {
  // New code
  final ScrollController _scrollController = ScrollController();
  bool _hasReloaded = false;

  @override
  void initState() {
    super.initState();
    // Reload menu data in background when entering EditMenuScreen to ensure fresh data
    // But don't block UI - show existing data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasReloaded && mounted) {
        _hasReloaded = true;
        final supplier = context.read<MenuSupplier>();
        // Only reload if menu is empty or we want to refresh
        // Reload in background without blocking UI
        if (supplier.menu.isEmpty) {
          // If menu is empty, reload immediately (will show loading)
          supplier.reload();
        } else {
          // If menu has data, reload in background silently (won't show loading indicator)
          supplier.reload(silent: true).catchError((e) {
            print('⚠️ Background reload failed: $e');
            // Don't show error to user if we have existing data
          });
        }
      }
    });
  }

  @override
  dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      onAddDish: (name, price, [image]) async {
        final supplier = context.read<MenuSupplier>();
        await supplier.addDish(name, price, image);
      },
      body: MenuFilterer(
        builder: (context, list) => ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(10.0),
          controller: _scrollController,
          itemCount: list.length,
          itemBuilder: (_, index) {
            return _ListItem(
              list[index],
              onShow: (ctx) {
                // ensure visibility of this widget after expanded (so it is not obscured by the appbar),
                // but only call after animation from the `AnimatedCrossFade` is completed so the `ctx.findRenderObject`
                // find the render object at full height to work with
                Timer(_animDuration, () {
                  _scrollController.position.ensureVisible(
                    ctx.findRenderObject()!,
                    duration: _animDuration,
                    curve: Curves.easeOut,
                    alignmentPolicy:
                        ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
                  );
                });
              },
              key: ObjectKey(list[index]),
            );
          },
        ),
      ),
    );
  }
}

class _ListItem extends HookWidget {
  final Function(BuildContext ctx) onShow;
  final Dish dish;

  const _ListItem(this.dish, {required this.onShow, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentState = useState(CrossFadeState.showFirst);

    return Card(
      child: AnimatedCrossFade(
        duration: _animDuration,
        crossFadeState: currentState.value,
        firstChild: collapsed(context, dish, currentState),
        secondChild: expanded(context, dish, currentState),
      ),
    );
  }

  Widget collapsed(BuildContext context, Dish dish,
      ValueNotifier<CrossFadeState> currentState) {
    return InkWell(
      onTap: () {
        currentState.value = CrossFadeState.showSecond;
        onShow(context);
      },
      onLongPress: () async {
        final supplier = context.read<MenuSupplier>();
        var delete = await popUpDelete(context);
        if (delete != null && delete) {
          supplier.removeDish(dish);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dish.dish),
            Chip(
              label: Text(Money.format(dish.price)),
              labelStyle: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget expanded(BuildContext context, Dish dish,
      ValueNotifier<CrossFadeState> currentState) {
    final dishNameController = useTextEditingController(text: dish.dish);
    final priceController =
        useTextEditingController(text: Money.format(dish.price));
    final pickedImage = useState<Uint8List?>(null);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FormContent(
        inputs: buildInputs(
            context, dishNameController, priceController, TextAlign.start),
        avatar: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.restaurant_menu,
            size: 50,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        gap: 12.0,
        buttonMinWidth: 70.0,
        onSubmit: () {
          if (priceController.text.isNotEmpty &&
              dishNameController.text.isNotEmpty) {
            final supplier = context.read<MenuSupplier>();
            supplier.updateDish(
              dish,
              dishNameController.text,
              Money.unformat(priceController.text).toDouble(),
              pickedImage.value,
            );
            currentState.value = CrossFadeState.showFirst;
          }
        },
        onCancel: () {
          currentState.value = CrossFadeState.showFirst;
        },
      ),
    );
  }
}
