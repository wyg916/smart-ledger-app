package com.offline.ledger.ui.screens

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.DragHandle
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import androidx.hilt.navigation.compose.hiltViewModel
import com.offline.ledger.data.db.entity.CategoryEntity
import com.offline.ledger.model.TransactionType
import com.offline.ledger.ui.components.CategoryIcons
import com.offline.ledger.ui.viewmodel.CategoriesEvent
import com.offline.ledger.ui.viewmodel.CategoriesViewModel
import kotlin.math.roundToInt

private val IconChoices: List<String> = CategoryIcons.choices

@Composable
@OptIn(ExperimentalMaterial3Api::class)
fun CategoriesScreen(
    onBack: () -> Unit,
    viewModel: CategoriesViewModel = hiltViewModel(),
) {
    val state = viewModel.uiState.collectAsState().value
    val context = androidx.compose.ui.platform.LocalContext.current

    val localList = remember { mutableStateListOf<CategoryEntity>() }
    var draggingIndex by remember { mutableStateOf<Int?>(null) }
    var dragOffsetY by remember { mutableStateOf(0f) }

    var showEditDialog by remember { mutableStateOf(false) }
    var editingCategory: CategoryEntity? by remember { mutableStateOf(null) }
    var editName by remember { mutableStateOf("") }
    var editIcon by remember { mutableStateOf("other") }
    var iconManuallyPicked by remember { mutableStateOf(false) }

    var showDeleteConfirm by remember { mutableStateOf(false) }

    LaunchedEffect(state.categories) {
        if (draggingIndex == null) {
            localList.clear()
            localList.addAll(state.categories)
        }
    }

    LaunchedEffect(Unit) {
        viewModel.events.collect { e ->
            when (e) {
                is CategoriesEvent.Toast -> Toast.makeText(context, e.message, Toast.LENGTH_SHORT).show()
            }
        }
    }

    if (showEditDialog) {
        AlertDialog(
            onDismissRequest = { showEditDialog = false },
            title = { Text(if (editingCategory == null) "新增分类" else "编辑分类") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = editName,
                        onValueChange = { newValue ->
                            editName = newValue
                            if (editingCategory == null && !iconManuallyPicked) {
                                val used = state.categories.map { it.iconCode }.toSet()
                                editIcon = CategoryIcons.suggestCodeForName(newValue, used)
                            }
                        },
                        label = { Text("名称") },
                        singleLine = true,
                    )
                    Text("图标")
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(6),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(220.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        items(IconChoices) { code ->
                            IconButton(
                                onClick = {
                                    editIcon = code
                                    iconManuallyPicked = true
                                },
                            ) {
                                val tint = if (editIcon == code) {
                                    MaterialTheme.colorScheme.primary
                                } else {
                                    MaterialTheme.colorScheme.onSurface
                                }
                                Icon(CategoryIcons.forCode(code), contentDescription = code, tint = tint)
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        val name = editName.trim()
                        if (name.isBlank()) return@TextButton
                        val existing = editingCategory
                        if (existing == null) {
                            viewModel.addCategory(name, editIcon)
                        } else {
                            viewModel.updateCategory(existing.copy(name = name, iconCode = editIcon))
                        }
                        showEditDialog = false
                    },
                ) { Text("保存") }
            },
            dismissButton = { TextButton(onClick = { showEditDialog = false }) { Text("取消") } },
        )
    }

    if (showDeleteConfirm && editingCategory != null) {
        val target = editingCategory!!
        AlertDialog(
            onDismissRequest = { showDeleteConfirm = false },
            title = { Text("确认删除？") },
            text = { Text("删除后该分类将不可用（历史记录仍保留分类名）。") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteConfirm = false
                        viewModel.deleteCategory(target)
                    },
                ) { Text("删除") }
            },
            dismissButton = { TextButton(onClick = { showDeleteConfirm = false }) { Text("取消") } },
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("类别设置") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "返回")
                    }
                },
                actions = {
                    IconButton(onClick = {
                        editingCategory = null
                        editName = ""
                        iconManuallyPicked = false
                        editIcon = CategoryIcons.suggestCodeForName("", state.categories.map { it.iconCode }.toSet())
                        showEditDialog = true
                    }) {
                        Icon(Icons.Outlined.Add, contentDescription = "新增")
                    }
                },
            )
        },
    ) { inner ->
        Column(
            modifier = Modifier.fillMaxSize().padding(inner).padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(
                    selected = state.type == TransactionType.Expense,
                    onClick = { viewModel.setType(TransactionType.Expense) },
                    label = { Text("支出") },
                )
                FilterChip(
                    selected = state.type == TransactionType.Income,
                    onClick = { viewModel.setType(TransactionType.Income) },
                    label = { Text("收入") },
                )
            }

            Text("长按右侧拖动排序", style = MaterialTheme.typography.bodySmall)

            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                itemsIndexed(localList, key = { _, item -> item.id }) { index, cat ->
                    val isDragging = draggingIndex == index
                    val offsetY = if (isDragging) dragOffsetY.roundToInt() else 0
                    ListItem(
                        modifier = Modifier
                            .fillMaxWidth()
                            .zIndex(if (isDragging) 1f else 0f)
                            .background(MaterialTheme.colorScheme.surface, MaterialTheme.shapes.medium)
                            .padding(vertical = 2.dp)
                            .then(
                                if (isDragging) Modifier else Modifier,
                            )
                            .offset { IntOffset(0, offsetY) },
                        leadingContent = { Icon(CategoryIcons.forCode(cat.iconCode), contentDescription = null) },
                        headlineContent = { Text(cat.name) },
                        supportingContent = { if (cat.isDefault) Text("默认分类") },
                        trailingContent = {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                IconButton(onClick = {
                                    editingCategory = cat
                                    editName = cat.name
                                    editIcon = cat.iconCode
                                    iconManuallyPicked = true
                                    showEditDialog = true
                                }) {
                                    Icon(Icons.Outlined.Edit, contentDescription = "编辑")
                                }
                                IconButton(
                                    enabled = !cat.isDefault,
                                    onClick = {
                                        editingCategory = cat
                                        showDeleteConfirm = true
                                    },
                                ) {
                                    Icon(Icons.Outlined.Delete, contentDescription = "删除")
                                }
                                Icon(
                                    Icons.Outlined.DragHandle,
                                    contentDescription = "拖动排序",
                                    modifier = Modifier
                                        .size(32.dp)
                                        .pointerInput(cat.id) {
                                            val itemHeightPx = 72.dp.toPx()
                                            detectDragGesturesAfterLongPress(
                                                onDragStart = {
                                                    draggingIndex = index
                                                    dragOffsetY = 0f
                                                },
                                                onDragCancel = {
                                                    draggingIndex = null
                                                    dragOffsetY = 0f
                                                },
                                                onDragEnd = {
                                                    draggingIndex = null
                                                    dragOffsetY = 0f
                                                    viewModel.reorder(localList.toList())
                                                },
                                                onDrag = { change, dragAmount ->
                                                    change.consume()
                                                    if (draggingIndex == null) return@detectDragGesturesAfterLongPress
                                                    dragOffsetY += dragAmount.y
                                                    var currentIndex = draggingIndex!!
                                                    while (dragOffsetY > itemHeightPx / 2 && currentIndex < localList.lastIndex) {
                                                        val item = localList.removeAt(currentIndex)
                                                        localList.add(currentIndex + 1, item)
                                                        currentIndex++
                                                        draggingIndex = currentIndex
                                                        dragOffsetY -= itemHeightPx
                                                    }
                                                    while (dragOffsetY < -itemHeightPx / 2 && currentIndex > 0) {
                                                        val item = localList.removeAt(currentIndex)
                                                        localList.add(currentIndex - 1, item)
                                                        currentIndex--
                                                        draggingIndex = currentIndex
                                                        dragOffsetY += itemHeightPx
                                                    }
                                                },
                                            )
                                        },
                                )
                            }
                        },
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                }
            }
        }
    }
}
