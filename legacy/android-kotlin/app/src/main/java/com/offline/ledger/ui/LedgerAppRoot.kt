package com.offline.ledger.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.BarChart
import androidx.compose.material.icons.outlined.List
import androidx.compose.material.icons.outlined.Public
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.zIndex
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.offline.ledger.ui.screens.AddTransactionScreen
import com.offline.ledger.ui.screens.BillsScreen
import com.offline.ledger.ui.screens.BudgetScreen
import com.offline.ledger.ui.screens.ChartsScreen
import com.offline.ledger.ui.screens.DiscoverScreen
import com.offline.ledger.ui.screens.DetailsScreen
import com.offline.ledger.ui.screens.CategoriesScreen
import com.offline.ledger.ui.screens.MineScreen
import com.offline.ledger.ui.screens.PinSetupScreen
import com.offline.ledger.ui.screens.SecurityScreen
import com.offline.ledger.ui.screens.ToolsScreen
import com.offline.ledger.ui.screens.TransactionDetailScreen

private enum class MainTab(
    val route: String,
    val label: String,
    val icon: ImageVector,
) {
    Details("details", "明细", Icons.Outlined.List),
    Charts("charts", "图表", Icons.Outlined.BarChart),
    Discover("discover", "发现", Icons.Outlined.Public),
    Mine("mine", "我的", Icons.Outlined.Person),
}

@Composable
fun LedgerAppRoot() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    val isFullScreenRoute = currentDestination?.route in setOf(
        "add",
        "edit/{txId}",
        "tx/{txId}",
        "tools",
        "bills",
        "budget",
        "budget/item/{itemId}",
        "security",
        "pin_setup",
        "categories",
    )

    Scaffold(
        bottomBar = {
            if (!isFullScreenRoute) {
                Box {
                    NavigationBar {
                        val slotRoutes: List<String?> = listOf(
                            MainTab.Details.route,
                            MainTab.Charts.route,
                            "add",
                            MainTab.Discover.route,
                            MainTab.Mine.route,
                        )

                        slotRoutes.forEach { route ->
                            if (route == null) return@forEach
                            if (route == "add") {
                                NavigationBarItem(
                                    selected = false,
                                    onClick = { navController.navigate("add") },
                                    icon = { Box(modifier = Modifier.size(24.dp)) },
                                    label = { Text("记账") },
                                    alwaysShowLabel = true,
                                )
                            } else {
                                val tab = MainTab.entries.first { it.route == route }
                                val selected = currentDestination?.hierarchy?.any { it.route == tab.route } == true
                                NavigationBarItem(
                                    selected = selected,
                                    onClick = {
                                        navController.navigate(tab.route) {
                                            popUpTo(navController.graph.findStartDestination().id) {
                                                saveState = true
                                            }
                                            launchSingleTop = true
                                            restoreState = true
                                        }
                                    },
                                    icon = { Icon(tab.icon, contentDescription = tab.label) },
                                    label = { Text(tab.label) },
                                )
                            }
                        }
                    }

                    FloatingActionButton(
                        modifier = Modifier
                            .align(Alignment.TopCenter)
                            .offset(y = (-18).dp)
                            .size(64.dp)
                            .zIndex(1f),
                        containerColor = MaterialTheme.colorScheme.primary,
                        onClick = { navController.navigate("add") },
                    ) {
                        Icon(Icons.Outlined.Add, contentDescription = "记一笔")
                    }
                }
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = MainTab.Details.route,
            modifier = Modifier.padding(innerPadding),
        ) {
            composable(MainTab.Details.route) {
                DetailsScreen(
                    onAdd = { navController.navigate("add") },
                    onOpen = { id -> navController.navigate("tx/$id") },
                    onEdit = { id -> navController.navigate("edit/$id") },
                )
            }
            composable(MainTab.Charts.route) { ChartsScreen() }
            composable(MainTab.Discover.route) {
                DiscoverScreen(
                    onOpenBills = { navController.navigate("bills") },
                    onOpenBudget = { navController.navigate("budget") },
                    onOpenBudgetItem = { id -> navController.navigate("budget/item/$id") },
                )
            }
            composable("add") {
                AddTransactionScreen(
                    onClose = { navController.popBackStack() },
                    onOpenCategories = { navController.navigate("categories") },
                )
            }
            composable("edit/{txId}") {
                AddTransactionScreen(
                    onClose = { navController.popBackStack() },
                    onOpenCategories = { navController.navigate("categories") },
                )
            }
            composable(MainTab.Mine.route) {
                MineScreen(
                    onOpenSecurity = { navController.navigate("security") },
                    onOpenCategories = { navController.navigate("categories") },
                    onOpenTools = { navController.navigate("tools") },
                )
            }

            composable("tools") { ToolsScreen(onBack = { navController.popBackStack() }) }
            composable("bills") {
                BillsScreen(onBack = { navController.popBackStack() })
            }
            composable("budget") {
                BudgetScreen(onBack = { navController.popBackStack() })
            }
            composable("budget/item/{itemId}") {
                BudgetScreen(onBack = { navController.popBackStack() })
            }

            composable("security") {
                SecurityScreen(
                    onBack = { navController.popBackStack() },
                    onSetupPin = { navController.navigate("pin_setup") },
                )
            }
            composable("pin_setup") {
                PinSetupScreen(onBack = { navController.popBackStack() })
            }

            composable("categories") {
                CategoriesScreen(onBack = { navController.popBackStack() })
            }

            composable("tx/{txId}") {
                TransactionDetailScreen(
                    onBack = { navController.popBackStack() },
                    onEdit = { id -> navController.navigate("edit/$id") },
                )
            }
        }
    }
}
